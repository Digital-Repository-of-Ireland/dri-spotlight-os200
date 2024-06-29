require 'google/analytics/data/v1beta'

module Spotlight
  module Analytics
    class Ga4ReportRequest

      DEFAULT_METRICS = ['screenPageViews'].freeze
      BEGINS_WITH_MATCH_TYPE = Google::Analytics::Data::V1beta::Filter::StringFilter::MatchType::BEGINS_WITH

      attr_reader :property_id
      attr_reader :page_path
      attr_reader :start_date
      attr_reader :end_date
      attr_reader :metrics

      def initialize(page_path:, start_date:, end_date:, property_id:, order_by: nil, metrics: nil)
        @page_path = page_path
        @start_date = start_date
        @end_date = end_date
        @property_id = property_id
        @metrics = metrics || DEFAULT_METRICS
        @order_by = order_by
      end

      def generate
        args = {
          property: "properties/#{property_id}",
          dimensions: [{ name: 'pagePath' }, { name: 'pageTitle'}],
          dimension_filter: dimension_filter(page_path),
          metrics: report_metrics,
          date_ranges: [{ start_date: start_date.to_s, end_date: end_date.to_s }],
        }
        args[:order_bys] = [order_bys] if @order_by

        Google::Analytics::Data::V1beta::RunReportRequest.new(**args)
      end

      private

      def report_metrics
        metrics.map { |metric| { name: metric } } # DEFAULT_METRICS
      end

      def dimension_filter(page_path)
        {
          filter: {
            field_name: 'pagePath',
            string_filter: {
              match_type: BEGINS_WITH_MATCH_TYPE,
              value: page_path,
              case_sensitive: false
            }
          }
        }
      end

      def order_bys
        order_by = {}
        order_by[:desc] = true if @order_by.key?(:desc)
        order_by[:metric] = { metric_name: @order_by[:metric] }
        
        order_by
      end
    end
  end
end