require 'logger'
require 'benchmark'

module NcboCron
  module Models
    class IndexSynchronizer
      class OntologiesReportError < StandardError; end

      PERCENT_CLASSES_TO_TEST = 25
      PERCENT_TEST_PAGE_SIZE = 5
      MIN_PAGED_THRESHOLD = 1000
      MAX_PAGE_SIZE = 2000

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

        acronyms = ['LOINC', 'FMA', 'UBERON', 'UO']

        ont_to_index = ontologies_to_index(acronyms)
      end

      def ontologies_to_index(acronyms = [])
        ont_to_index = []
        ontologies = LinkedData::Models::Ontology.where.include(:acronym).all
        ontologies.select! { |ont| acronyms.include?(ont.acronym) } unless acronyms.empty?

        ontologies.each do |ont|
          submission = ont.latest_submission(status: [:RDF])
          next if submission.nil?

          acronym = ont.acronym
          page_data = LinkedData::Models::Class.in(submission).page(1, MIN_PAGED_THRESHOLD).all
          total_count = page_data.aggregate
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

          puts "\n\nAcronym: #{acronym}"
          puts "Total Page Count: #{total_page_count}"
          puts "Test Page Count: #{test_page_count}"
          puts "Test Page Size: #{test_page_size}"
          puts "Test Page Nums: #{test_page_numbers}\n\n"

          test_page_numbers.each do |page_num|
            page_data = LinkedData::Models::Class.in(submission).page(page_num, test_page_size).all
            resource_ids = page_data.map { |cl| cl.id.to_s }
            search_query = search_query_params(ont.acronym, test_page_size, resource_ids)
            search_resp = LinkedData::Models::Class.search('*', search_query)
            total_found = search_resp['response']['numFound']

            puts "Page: #{page_num}"
            puts "Num classes: #{resource_ids.length}"
            puts "Num found: #{total_found}"
            puts "******************************************\n"

            if total_found < resource_ids.length
              ont_to_index << acronym
              break
            end
          end
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

        if words.length > 1
          query << "("
        end
        query << "\"#{words[0]}\""

        if words.length > 1
          words[1..-1].each do |word|
            query << " #{clause} \"#{word}\""
          end
        end

        if words.length > 1
          query << ")"
        end
        query
      end

    end
  end
end

require 'ontologies_linked_data'
require 'goo'
require 'ncbo_annotator'
require 'ncbo_cron/config'
require_relative '../../config/config'

index_synchronizer_path = File.join("logs", "index-synchronizer.log")
index_synchronizer_logger = Logger.new(index_synchronizer_path)
NcboCron::Models::IndexSynchronizer.new(index_synchronizer_logger).run
# ./bin/ncbo_cron --disable-processing true --disable-pull true --disable-flush true --disable-warmq true --disable-ontology-analytics true --disable-mapping-counts true --disable-spam-deletion true --disable-ontologies-report true --index-synchronizer '14 * * * *'


