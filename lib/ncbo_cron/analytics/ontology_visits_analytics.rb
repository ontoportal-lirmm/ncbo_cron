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
        @ont_acronyms = ['AGROVOC', 'E-PHY', 'CROPUSAGE']
      end


      def fetch_ua_object_analytics(logger, ua_conn)
        @logger = logger
        @ua_conn =  ua_conn
        aggregated_results = Hash.new
        start_year = Date.parse(UA_START_DATE).year || 2013
        filter_str = (@analytics_filter.nil? || @analytics_filter.empty?) ? "" : ";#{@analytics_filter}"

        @ont_acronyms.each do |acronym|
          max_results = 10000
          start_index = 1
          loop do
            results = @ua_conn.run_request(
              metrics: ['pageviews'],
              dimensions: %w[pagePath year month],
              filters: [['pagePath', "~^(\\/ontologies\\/#{acronym})(\\/?\\?{0}|\\/?\\?{1}.*)$#{filter_str}"]],
              start_index: start_index,
              max_results: max_results,
              dates_ranges: [UA_START_DATE, Date.today.to_s],
              sort: %w[year month]
            )
            results.rows ||= []
            start_index += max_results
            num_results = results.rows.length
            @logger.info "Acronym: #{acronym}, Results: #{num_results}, Start Index: #{start_index}"
            @logger.flush
            aggregated_results[acronym] = Hash.new unless aggregated_results.has_key?(acronym)
            aggregate_results(aggregated_results[acronym], results.rows)

            if num_results < max_results
              # fill up non existent years
              (start_year..Date.today.year).each do |y|
                aggregated_results[acronym] = Hash.new if aggregated_results[acronym].nil?
                aggregated_results[acronym][y.to_s] = Hash.new unless aggregated_results[acronym].has_key?(y.to_s)
              end
              # fill up non existent months with zeros
              (1..12).each { |n| aggregated_results[acronym].values.each { |v| v[n.to_s] = 0 unless v.has_key?(n.to_s) } }
              break
            end
          end
        end
        sort_ga_data(aggregated_results)
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
