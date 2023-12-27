require 'logger'
require 'json'
require 'benchmark'
require 'google/analytics/data'
require 'google/apis/analytics_v3'
require 'google/api_client/auth/key_utils'

module NcboCron
  module Models
    UA_START_DATE = '2013-10-01'
    GA4_START_DATE = '2023-06-01'

    class GoogleAnalyticsConnector

      attr_reader :ga_client

      def initialize
        @ga_data_file = NcboCron.settings.analytics_path_to_ga_data_file
        @ua_data_file = NcboCron.settings.analytics_path_to_ua_data_file
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

    # Old version of Google Analytics
    class GoogleAnalyticsUAConnector
      def initialize
        @app_id = NcboCron.settings.analytics_profile_id
        @app_name = NcboCron.settings.analytics_app_name
        @app_version = NcboCron.settings.analytics_app_version
        @analytics_key_file = NcboCron.settings.ua_analytics_path_to_key_file
        @app_user = NcboCron.settings.analytics_service_account_email_address
        @generated_file_path = NcboCron.settings.analytics_path_to_ua_data_file
        @start_date = NcboCron.settings.analytics_start_date
        @analytics_filter = NcboCron.settings.analytics_filter_str
        @ga_client = authenticate_google
      end

      def run_request(metrics:, dimensions:, filters:, start_index:, max_results:, dates_ranges:, sort:)
        @ga_client.get_ga_data(
          ids = @app_id,
          start_date = dates_ranges.first,
          end_date = dates_ranges.last,
          metrics = metrics.map { |m| "ga:#{m}" }.join(','),
          {
            dimensions: dimensions.map { |d| "ga:#{d}" }.join(','),
            filters: filters.empty? ? nil : filters.map { |f, v| "ga:#{f}=#{v}" }.join(','),
            start_index: start_index,
            max_results: max_results,
            sort: sort.map { |d| "ga:#{d}" }.join(',')
          }
        )
      end

      private

      def authenticate_google
        Google::Apis::ClientOptions.default.application_name = @app_name
        Google::Apis::ClientOptions.default.application_version = @app_version
        # enable google api call retries in order to
        # minigate analytics processing failure due to occasional google api timeouts and other outages
        Google::Apis::RequestOptions.default.retries = 5
        # uncoment to enable logging for debugging purposes
        # Google::Apis.logger.level = Logger::DEBUG
        # Google::Apis.logger = @logger
        client = Google::Apis::AnalyticsV3::AnalyticsService.new
        key = Google::APIClient::KeyUtils::load_from_pkcs12(@analytics_key_file, 'notasecret')
        client.authorization = Signet::OAuth2::Client.new(
          :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
          :audience => 'https://accounts.google.com/o/oauth2/token',
          :scope => 'https://www.googleapis.com/auth/analytics.readonly',
          :issuer => @app_user,
          :signing_key => key
        ).tap { |auth| auth.fetch_access_token! }
        client
      end

    end

    class ObjectAnalytics

      attr_reader :redis_field

      def initialize(redis_field:, start_date:, old_data: {})
        @redis_field = redis_field
        @start_date = Date.parse(start_date) rescue Date.parse(NcboCron.settings.analytics_start_date)
        @old_data = old_data[@redis_field] || {}
      end

      def full_data(logger, ga_conn, ua_conn)

        logger.info "Fetching GA4 analytics for all ontologies from #{@start_date} to today..."
        logger.flush
        new_ga_data = fetch_object_analytics(logger, ga_conn)

        if @start_date < Date.parse(GA4_START_DATE)
          @old_data = {}
          logger.info "Fetching UA analytics for all ontologies from #{@start_date} to today..."
          logger.flush
          ua_data = fetch_ua_object_analytics(logger, ua_conn)
          logger.info "Completed Universal Analytics pull..."
          logger.flush
          new_ga_data = merge_and_fill_missing_data(new_ga_data, ua_data, logger)
        end
        merge_and_fill_missing_data(new_ga_data, @old_data, logger)
      end

      # @param ga_conn GoogleAnalyticsConnector
      def fetch_object_analytics(logger, ga_conn)
        raise NotImplementedError, "Subclasses must implement this method"
      end

      # @param ua_conn GoogleAnalyticsUAConnector
      def fetch_ua_object_analytics(logger, ua_conn)
        raise NotImplementedError, "Subclasses must implement this method"
      end

      private

      def merge_and_fill_missing_data(new_data, old_data,logger, start_date = @start_date)
        if !old_data.empty?
          logger.info "Merging GA4 and UA data..."
          logger.flush
          old_data.keys.each do |acronym|
            (start_date.year..Date.today.year).each do |year|
              year = year.to_s
              # add up hits for June of 2023 (the only intersecting month between UA and GA4)
              if old_data[acronym].has_key?(year)
                next unless new_data[acronym].has_key?(year)

                (1..Date.today.month).each do |month|
                  month = month.to_s
                  old_data[acronym][year][month] ||= 0
                  unless old_data[acronym][year][month].eql?(new_data[acronym][year][month])
                    old_data[acronym][year][month] += (new_data[acronym][year][month] || 0)
                  end
                end

              elsif new_data[acronym][year]
                old_data[acronym][year] = new_data[acronym][year]
              end
            end
          end
          old_data = fill_missing_data(old_data)
        else
          old_data = new_data
        end

        # fill missing years and months
        logger.info "Filling in missing years data..."
        logger.flush
        old_data
        # sort_ga_data(old_data)
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
        start_year = Date.parse(UA_START_DATE).year

        ga_data.each do |acronym, _|
          (start_year..Date.today.year).each do |y|
            ga_data[acronym] = Hash.new if ga_data[acronym].nil?
            ga_data[acronym][y.to_s] = Hash.new unless ga_data[acronym].has_key?(y.to_s)
          end
          # fill up non existent months with zeros
          (1..12).each { |n| ga_data[acronym].values.each { |v| v[n.to_s] = 0 if v.is_a?(Hash) && !v.has_key?(n.to_s) } }
        end
      end

      def sort_ga_data(ga_data)
        ga_data.transform_values { |value|
          value.transform_values { |val|
            val.sort_by { |key, _| key.to_i }.to_h
          }.sort_by { |k, _| k.to_i }.to_h
        }.sort.to_h
      end

    end
  end
end
