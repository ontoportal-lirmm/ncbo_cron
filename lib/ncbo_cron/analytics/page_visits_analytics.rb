require 'logger'
require 'json'
require 'benchmark'
require_relative 'object_analytics'

module NcboCron
  module Models
    class PageVisitsAnalytics < ObjectAnalytics
      def initialize(start_date: Date.today.prev_month, old_data: {})
        super(redis_field: 'pages_analytics', start_date: start_date, old_data: { })
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
            metrics: ['screenPageViews'],
            dimensions: %w[pagePathPlusQueryString],
            order_bys: %w[screenPageViews],
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
          aggregated_results = {}
          response.rows.each do |row|
            row_h = row.to_h
            year_month_hits = row_h[:dimension_values].map{ |x| x[:value] } + [row_h[:metric_values].first[:value]]
            results << year_month_hits
            page_count = year_month_hits[1].to_i
            page_path = year_month_hits[0]
            page_path = year_month_hits[0].chop  if page_path.end_with?('/') && !page_path.eql?('/')
            if page_count >= 10
              old_page_count = aggregated_results[page_path] || 0
              aggregated_results[page_path] = old_page_count + page_count
            end
          end

          break if num_results < max_results
        end
        {"all_pages" => aggregated_results }
      end

      def fetch_ua_object_analytics(logger, ua_conn)
        {"all_pages" => {} } # we fetch only the current month views UA is at least 6 month past
      end
    end
  end
end

