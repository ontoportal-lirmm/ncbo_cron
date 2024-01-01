require 'logger'
require 'json'
require 'benchmark'
require 'google/analytics/data'
require 'google/apis/analytics_v3'
require 'google/api_client/auth/key_utils'

module NcboCron
  module Models



    class GoogleAnalyticsConnector

      attr_reader :ga_client

      def initialize
        @app_id = NcboCron.settings.analytics_property_id
        @app_key_file = NcboCron.settings.analytics_path_to_key_file
        @ga_client = analytics_data_client
      end

      def run_request(metrics:, dimensions:, date_ranges:, order_bys:, offset:, limit:, dimension_filter:)
        request = Google::Analytics::Data::V1beta::RunReportRequest.new(
          property: "properties/#{@app_id}",
          metrics: metrics.map { |m| ga_metric(m) },
          dimension_filter: dimension_filter.empty? ? nil : ga_filter(*dimension_filter),
          dimensions: dimensions.map { |d| ga_dimension(d) },
          date_ranges: [ga_date_range(*date_ranges)],
          order_bys: order_bys.map { |o| ga_order_by(o) },
          offset: offset,
          limit: limit
        )

        @ga_client.run_report request
      end

      private

      def analytics_data_client
        Google::Analytics::Data.analytics_data do |config|
          config.credentials = @app_key_file
        end
      end

      def ga_metric(name)
        Google::Analytics::Data::V1beta::Metric.new(
          name: name
        )
      end

      def ga_date_range(start_date, end_date)
        Google::Analytics::Data::V1beta::DateRange.new(
          start_date: start_date,
          end_date: end_date
        )
      end

      def ga_dimension(name)
        Google::Analytics::Data::V1beta::Dimension.new(
          name: name
        )
      end

      def ga_filter(field_name, value)
        string_filter = Google::Analytics::Data::V1beta::Filter::StringFilter.new(
          match_type: Google::Analytics::Data::V1beta::Filter::StringFilter::MatchType::FULL_REGEXP,
          value: value
        )

        filter = Google::Analytics::Data::V1beta::Filter.new(
          field_name: field_name,
          string_filter: string_filter
        )
        Google::Analytics::Data::V1beta::FilterExpression.new(filter: filter)
      end

      def ga_order_by(dimension_name, desc = false)
        order = Google::Analytics::Data::V1beta::OrderBy::DimensionOrderBy.new(
          dimension_name: dimension_name
        )
        Google::Analytics::Data::V1beta::OrderBy.new(
          desc: desc,
          dimension: order
        )
      end

    end

    class ObjectAnalytics
      GA4_START_DATE = '2023-06-01'
      attr_reader :redis_field

      def initialize(redis_field:, start_date:, old_data: {})
        @redis_field = redis_field
        @start_date = Date.parse(start_date) rescue Date.parse(NcboCron.settings.analytics_start_date)
        @old_data = old_data[@redis_field] || {}
      end

      def full_data(logger, ga_conn)

        logger.info "Fetching GA4 analytics for #{@redis_field} from #{@start_date} to today..."
        logger.flush
        new_ga_data = fetch_object_analytics(logger, ga_conn)

        merge_and_fill_missing_data(new_ga_data, @old_data, logger)
      end

      # @param ga_conn GoogleAnalyticsConnector
      def fetch_object_analytics(logger, ga_conn)
        raise NotImplementedError, "Subclasses must implement this method"
      end

      private

      def merge_and_fill_missing_data(new_data, old_data,logger, start_date = @start_date)
        unless new_data.empty?
          logger.info "Merging old Google Analytics and the new data..."
          logger.flush
          new_data.keys.each do |acronym|
            if old_data.has_key?(acronym)
              (start_date.year..Date.today.year).each do |year|
                year = year.to_s
                if new_data[acronym].has_key?(year)
                  if old_data[acronym].has_key?(year)
                    last_month = year.eql?(Date.today.year) ? Date.today.month : 12
                    (1..last_month).each do |month|
                      month = month.to_s
                      old_data[acronym][year][month] ||= 0
                      unless old_data[acronym][year][month].eql?(new_data[acronym][year][month])
                        new_count = new_data[acronym][year][month] || 0
                        old_data[acronym][year][month] = new_count unless new_count.zero?
                      end
                    end
                  else
                    old_data[acronym][year] = new_data[acronym][year]
                  end
                end
              end
            else
              old_data[acronym] = new_data[acronym]
            end
          end
          # fill missing years and months
          logger.info "Filling in missing years data..."
          old_data = fill_missing_data(old_data)
        end
        sort_ga_data(old_data)
      end

      def aggregate_results(aggregated_results, results)
        results.each do |row|

          year = row[1].to_i.to_s
          month = row[2].to_i.to_s
          value = row[3].to_i
          aggregated = aggregated_results
          # year
          if aggregated.has_key?(year)
            # month
            if aggregated[year].has_key?(month)
              aggregated[year][month] += value
            else
              aggregated[year][month] = value
            end
          else
            aggregated[year] = Hash.new
            aggregated[year][month] = value
          end
        end
      end

      def fill_missing_data(ga_data)
        # fill up non existent years
        start_year = @start_date.year

        ga_data.each do |acronym, _|
          (start_year..Date.today.year).each do |y|
            ga_data[acronym] = Hash.new if ga_data[acronym].nil?
            ga_data[acronym][y.to_s] = Hash.new unless ga_data[acronym].has_key?(y.to_s)

            # fill up non existent months with zeros
            last_month = y.eql?(Date.today.year) ? Date.today.month.to_i : 12
            (1..last_month).each { |n| ga_data[acronym][y.to_s][n.to_s] = 0 if ga_data[acronym][y.to_s].is_a?(Hash) && !ga_data[acronym][y.to_s].has_key?(n.to_s) }
          end
        end
      end

      def sort_ga_data(ga_data)
        ga_data.transform_values { |value|
          value.transform_values { |val|
            if val.is_a?(Hash)
              val.sort_by { |key, _| key.to_i }.to_h
            else
              val
            end
          }.sort_by { |k, _| k.to_i }.to_h
        }.sort.to_h
      end

    end
  end
end
