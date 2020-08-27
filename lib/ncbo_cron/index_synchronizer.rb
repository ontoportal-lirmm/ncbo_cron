require 'logger'
require 'benchmark'
require_relative 'ontology_submission_parser'

module NcboCron
  module Models
    class IndexSynchronizer
      class OntologiesReportError < StandardError; end
      # Redis prefix for values stored for this job
      REDIS_PREFIX = 'index_synchronizer:'
      # Percentage of classes to test from a single ontology
      PERCENT_CLASSES_TO_TEST = 25
      # From the pool of classes to test, percentage of classes
      # grouped in a single page. The smaller the number, the
      # more pages to be tested and the more randomized the pool
      PERCENT_TEST_PAGE_SIZE = 5
      # Minimum number of classes in an ontology that warrant a
      # paged test. If the total number of classes is lower,
      # ALL classes are to be tested.
      MIN_PAGED_THRESHOLD = 1000
      # Maximum number of classes per page
      MAX_PAGE_SIZE = 2000
      # Minimum number of days elapsed from the previous test
      # that warrant a re-test of a specific ontology
      ONTOLOGY_RESYNC_NUM_DAYS_MIN = 15
      # Maximum number of days elapsed from the previous test
      # that warrant a re-test of a specific ontology
      ONTOLOGY_RESYNC_NUM_DAYS_MAX = 40
      # Maximum number of failed retries to reindex a given
      # ontology. If the ontology fails to sync beyond that
      # number of times, that fact is logged and the ontology
      # is no longer picked for a re-sync.
      MAX_FAILED_RETRIES = 4

      def initialize(logger=nil)
        @logger = nil

        if logger.nil?
          log_file = File.new(NcboCron.settings.log_path, "a")
          log_path = File.dirname(File.absolute_path(log_file))
          log_filename_no_ext = File.basename(log_file, ".*")
          index_synchronizer_log_path = File.join(log_path, "#{log_filename_no_ext}-index-synchronizer.log")
          @logger = Logger.new(index_synchronizer_log_path)
        else
          @logger = logger
        end
      end

      def run
        run_synchronizer
      end

      def run_synchronizer(acronyms = [])
        # acronyms = ['SO', 'NBO', 'ABD', 'CHEAR']
        # acronyms = ['CHEAR', 'ABD']
        ont_to_index = []

        time = Benchmark.realtime do
          ont_to_index = ontologies_to_index(acronyms)
        end
        output = "Completed the index synchronization run in #{(time / 60).round(1)} minutes."

        if ont_to_index.empty?
          output << ' ALL ontologies are in sync with the search index.'
        else
          output << " Ontologies queued for re-indexing:\n"
          output << ont_to_index.join(', ')
        end
        @logger.info output
      end

      def ontologies_to_index(acronyms = [])
        ont_to_index = []
        redis = Redis.new(host: NcboCron.settings.redis_host, port: NcboCron.settings.redis_port)
        ontologies = LinkedData::Models::Ontology.where.include(:acronym, :submissionId).all
        ontologies.select! { |ont| acronyms.include?(ont.acronym) } unless acronyms.empty?

        ontologies.each do |ont|
          submission = ont.latest_submission(status: [:RDF])
          next if submission.nil?

          acronym = ont.acronym
          submission.bring(:submissionId) if submission.bring?(:submissionId)
          current_submission_id = submission.submissionId
          synced_submission_id = current_submission_id
          registry_data = redis.hgetall("#{REDIS_PREFIX}#{acronym}")
          # Choosing re-sync number of days elapsed at random between MIN and MAX to avoid
          # the majority of the ontologies to be due for a re-sync on a single given day.
          # Choosing this number at random (in range) allows for staggered re-syncs
          resync_num_days = rand(ONTOLOGY_RESYNC_NUM_DAYS_MIN..ONTOLOGY_RESYNC_NUM_DAYS_MAX)
          last_synced_date = DateTime.now - resync_num_days - 1
          is_synced = false
          num_failures = 0
          msg_synced = ''

          unless registry_data.empty?
            is_synced = registry_data['is_synced'] == "true"
            num_failures = registry_data['num_failures'].to_i
            msg_synced = " The ontology was not synced at last run. Failed #{num_failures} runs." unless is_synced
            synced_submission_id = registry_data['submission_id'].to_i
            last_synced_date = DateTime.parse(registry_data['last_synced_date'])
          end
          time_now = DateTime.now
          last_synced_diff = (time_now - last_synced_date).to_i
          @logger.info "Processing ontology #{acronym}"
          no_resync = is_synced && current_submission_id == synced_submission_id && last_synced_diff < resync_num_days
          msg = "Last sync #{last_synced_diff} days ago. Re-sync required number of days: #{resync_num_days}."
          msg << ' Detected a new submission ID.' unless current_submission_id == synced_submission_id
          msg << (no_resync ? " No re-sync required. Skipping...\n\n" : "#{msg_synced} Proceeding with a re-sync.\n\n")
          @logger.info msg
          next if no_resync

          last_synced_date = time_now
          page_data = LinkedData::Models::Class.in(submission).page(1, 1).all
          total_count = page_data.aggregate
          total_test_count = total_count
          test_page_size = total_count
          test_page_count = 1
          total_page_count = 1
          test_page_numbers = [1]

          if total_count > MIN_PAGED_THRESHOLD
            total_test_count = (total_count * PERCENT_CLASSES_TO_TEST / 100).round
            test_page_size = (total_test_count * PERCENT_TEST_PAGE_SIZE / 100).round
            test_page_size = MAX_PAGE_SIZE if test_page_size > MAX_PAGE_SIZE
            test_page_count = (total_test_count / test_page_size.to_f).ceil
            total_page_count = (total_count / test_page_size.to_f).ceil
            test_page_numbers = (1..total_page_count).to_a.sort { rand - 0.5 }[1..test_page_count].sort
          end
          @logger.info "Total Classes: #{total_count}"
          @logger.info "Total Test Classes: #{total_test_count}"
          @logger.info "Test Page Size: #{test_page_size}"
          @logger.info "Total Number of Pages: #{total_page_count}"
          @logger.info "Test Number of Pages: #{test_page_count}"
          @logger.info "Test Page Numbers: #{test_page_numbers}\n"

          test_page_numbers.each do |page_num|
            page_data = LinkedData::Models::Class.in(submission).page(page_num, test_page_size).all
            resource_ids = page_data.map { |cl| cl.id.to_s }
            search_query = search_query_params(ont.acronym, test_page_size, resource_ids)
            search_resp = LinkedData::Models::Class.search('*', search_query)
            total_found = search_resp['response']['numFound']
            # @logger.info "Page: #{page_num}"
            # @logger.info "Number of classes: #{resource_ids.length}"
            # @logger.info "Num found: #{total_found}"
            # @logger.info "*********************\n"

            if total_found < resource_ids.length
              found_ids = search_resp['response']['docs'].map { |cl| cl['resource_id'] }
              @logger.info "Page: #{page_num}"
              @logger.info "Number of classes: #{resource_ids.length}"
              @logger.info "Num found: #{total_found}"
              @logger.info "*********************\n"
              ont_to_index << acronym
              is_synced = false
              num_failures += 1

              if num_failures > MAX_FAILED_RETRIES
                @logger.error "********************************************************************"
                @logger.error "Ontology #{acronym} failed to be synchronized #{num_failures} times. Please troubleshoot manually."
                @logger.error "********************************************************************"
              else
                NcboCron::Models::OntologySubmissionParser.new.queue_submission(submission, { index_search: true })
                @logger.info "Ontology #{acronym} is missing classes from the index. Queued for re-indexing."
                @logger.info "Classes missing from the index: #{(resource_ids - found_ids)}"
              end
              break
            else
              is_synced = true
            end
          end
          redis.hmset("#{REDIS_PREFIX}#{acronym}", "submission_id", current_submission_id, "is_synced", is_synced, "num_failures", num_failures, "last_synced_date", last_synced_date)
        end
        ont_to_index
      end

      def search_query_params(acronym, page_size, resource_ids)
        filter_query = get_quoted_field_query_param(resource_ids, 'OR', 'resource_id')
        {
            "defType" => "edismax",
            "stopwords" => "true",
            "lowercaseOperators" => "true",
            "fl" => "resource_id",
            "hl" => "on",
            "hl.simple.pre" => "<em>",
            "hl.simple.post" => "</em>",
            # "qf" => "resource_id^100 prefLabelExact^90 prefLabel^70 synonymExact^50 synonym^10 notation cui semanticType",
            # "hl.fl" => "resource_id prefLabelExact prefLabel synonymExact synonym notation cui semanticType",
            "fq" => "submissionAcronym:\"#{acronym}\" AND (#{filter_query})",
            "page" => 1,
            "pagesize" => page_size,
            "start" => 0,
            "rows" => page_size
        }
      end

      def get_quoted_field_query_param(words, clause, field_name = "")
        query = field_name.empty? ? "" : "#{field_name}:"
        query << "(" if words.length > 1
        query << "\"#{words[0]}\""
        words[1..-1].each { |word| query << " #{clause} \"#{word}\"" } if words.length > 1
        query << ")" if words.length > 1
        query
      end

    end
  end
end

# require 'ontologies_linked_data'
# require 'goo'
# require 'ncbo_annotator'
# require 'ncbo_cron/config'
# require_relative '../../config/config'
#
# NcboCron::Models::IndexSynchronizer.new(Logger.new(STDOUT)).run
# ./bin/ncbo_cron --disable-processing true --disable-pull true --disable-flush true --disable-warmq true --disable-ontology-analytics true --disable-mapping-counts true --disable-spam-deletion true --disable-ontologies-report true --index-synchronizer '14 * * * *'


