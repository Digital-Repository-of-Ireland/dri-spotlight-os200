require "google/analytics/data/v1beta/analytics_data"

module Spotlight
  module Analytics
    class Ga4Report

      LIMIT = 1000

      def client
        @client ||= auth_client
      end

      def get(page_path:, start_date:, end_date:, options: {})
        start_date = start_date.is_a?(String) ? start_date : start_date.strftime("%Y-%m-%d")

        args = { 
          page_path: page_path,
          start_date: start_date,
          end_date: end_date,
          property_id: config.property_id,
          metrics: ['sessions', 'totalUsers', 'screenPageViews']
        }.merge(options)

        request = Spotlight::Analytics::Ga4ReportRequest.new(
          **args
        ).generate

        run_report(request)
      end

      def run_report(request)
        offset = 0
        results = []
        request.offset = 0

        loop do
          report = auth_client.run_report(request)

          dimension_headers = report.dimension_headers.map(&:name)
          metric_headers = report.metric_headers.map(&:name)

          report.rows.each do |row|
            dimension_values = row.dimension_values.map(&:value)
            metric_values = row.metric_values.map(&:value)

            result_row = {}
            dimension_headers.each_with_index do |header,index|
              result_row[header] = dimension_values[index]
            end
              metric_headers.each_with_index do |header,index|
              result_row[header] = metric_values[index]
            end

            results << result_row
          end
          break if results.size == report.row_count

          offset += LIMIT
          request.offset = offset
        end

        results
      end

      def auth_client
        json_credentials = config.json_credentials
        raise "Credentials for Google analytics was expected at '#{config.json_credentials}', but no file was found." unless File.exist?(config.json_credentials)

        ::Google::Analytics::Data::V1beta::AnalyticsData::Client.new do |client_config|
          client_config.credentials = json_credentials
        end
      end

      def config
        @config ||= Config.load_from_yaml
      end

      class Config
        def self.load_from_yaml
          filename = Rails.root.join('config', 'analytics.yml')
          yaml = YAML.safe_load(ERB.new(File.read(filename)).result)
          unless yaml
            Rails.logger.error("Unable to fetch any keys from #{filename}.")
            return new({})
          end
          config = yaml.fetch('analytics')&.fetch('ga4', nil)
          new config
        end

        KEYS = %w[property_id json_credentials].freeze
        REQUIRED_KEYS = %w[property_id json_credentials].freeze

        def initialize(config)
          @config = config
        end

        # @return [Boolean] are all the required values present?
        def valid?
          REQUIRED_KEYS.all? { |required| @config[required].present? }
        end

        KEYS.each do |key|
          class_eval %{ def #{key}; @config.fetch('#{key}'); end }
          class_eval %{ def #{key}=(value); @config['#{key}'] = value; end }
          KEYS.each do |key|
            class_eval %{ def #{key}; @config.fetch('#{key}'); end }
            class_eval %{ def #{key}=(value); @config['#{key}'] = value; end }
          end
        end
      end
    end
  end
end