require 'logger'
require 'json'
require 'benchmark'
require_relative 'object_analytics'

module NcboCron
  module Models
    class UsersVisitsAnalytics < ObjectAnalytics
      def initialize(start_date: , old_data: {})
        super(redis_field: 'user_analytics', start_date: start_date, old_data: old_data)
      end

      private

      def fetch_object_analytics(logger, ga_conn)
        @logger = logger
        @ga_conn = ga_conn

        aggregated_results = Hash.new
        max_results = 10000



        start_index = 0
        loop do
          response = @ga_conn.run_request(
            date_ranges: [[@start_date, Date.parse(GA4_START_DATE)].max.to_s, Date.today.to_s],
            metrics: ['newUsers'],
            dimensions: %w[year month],
            order_bys: %w[year month],
            dimension_filter: [],
            offset: start_index,
            limit: max_results
          )

          response.rows ||= []
          num_results = response.rows.length
          @logger.info "Results: #{num_results}, Start Index: #{start_index}"
          @logger.flush
          start_index += max_results
          results = []
          response.rows.each do |row|
            row_h = row.to_h
            year_month_hits = row_h[:dimension_values].map{ |x| x[:value] } + [row_h[:metric_values].first[:value]]
            results << ([-1] + year_month_hits)
          end
          aggregate_results(aggregated_results, results)
          break if num_results < max_results

        end
        {"all_users" => aggregated_results}
      end


    end
  end
end

