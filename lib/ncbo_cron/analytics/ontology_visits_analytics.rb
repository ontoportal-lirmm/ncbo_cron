require 'logger'
require 'json'
require 'benchmark'
require_relative 'object_analytics'

module NcboCron
  module Models

    class OntologyVisitsAnalytics < ObjectAnalytics

      ONTOLOGY_ANALYTICS_REDIS_FIELD = 'ontology_analytics'

      def initialize(start_date: , old_data: {})
        super(redis_field: ONTOLOGY_ANALYTICS_REDIS_FIELD, start_date: start_date, old_data: old_data)
        @ont_acronyms = LinkedData::Models::Ontology.where.include(:acronym).all.map { |o| o.acronym }
      end

      def fetch_object_analytics(logger, ga_conn)
        @logger = logger
        @ga_conn = ga_conn

        aggregated_results = Hash.new
        max_results = 10000

        @ont_acronyms.each do |acronym|
          start_index = 0
          filer_regex = "^(\\/ontologies\\/#{acronym})(\\/?\\?{0}|\\/?\\?{1}.*)$"

          loop do
            response = @ga_conn.run_request(
              date_ranges: [[@start_date, Date.parse(GA4_START_DATE)].max.to_s, Date.today.to_s],
              metrics: ['screenPageViews'],
              dimensions: %w[pagePath year month],
              order_bys: %w[year month],
              dimension_filter: ['pagePath', filer_regex],
              offset: start_index,
              limit: max_results
            )

            response.rows ||= []
            num_results = response.rows.length
            @logger.info "Acronym: #{acronym}, Results: #{num_results}, Start Index: #{start_index}"
            @logger.flush
            start_index += max_results
            results = []

            response.rows.each do |row|
              row_h = row.to_h
              year_month_hits = row_h[:dimension_values].map.with_index {
                |v, i| i > 0 ? v[:value].to_s : row_h[:metric_values][0][:value].to_s
              }.rotate(1)
              results << ([acronym] + year_month_hits)
            end
            aggregated_results[acronym] = Hash.new unless aggregated_results.has_key?(acronym)
            aggregate_results(aggregated_results[acronym], results)
            break if num_results < max_results
          end
        end
        aggregated_results
      end
    end

  end
end
