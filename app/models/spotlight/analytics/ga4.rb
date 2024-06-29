# frozen_string_literal: true
module Spotlight
  module Analytics
    ##
    # Google Analytics 4 data provider for the Exhibit dashboard
    class Ga4

      def enabled?
        report
      end
    
      def metrics
        OpenStruct.new(elements: [:pageviews, :users, :sessions])
      end

      def exhibit_data(exhibit, options)
        results = report.get(
          page_path: page_path(exhibit),
          start_date: options[:start_date],
          end_date: options[:end_date].presence || 'today'
        ).first

        return exhibit_data_unavailable unless results

        OpenStruct.new(pageviews: results['screenPageViews'], users: results['totalUsers'], sessions: results['sessions'])
      end

      def page_data(exhibit, options)
        results = report.get(
          page_path: page_path(exhibit),
          start_date: options[:start_date],
          end_date: options[:end_date].presence || 'today',
          options: { order_by: { desc: true, metric: 'screenPageViews'}}
        )
        results.map { |r| OpenStruct.new(pageTitle: r['pageTitle'], pagePath: r['pagePath'], pageviews: r['screenPageViews']) }
      end

      def report
        @report ||= Ga4Report.new
      end

      private
  
      def exhibit_data_unavailable
        OpenStruct.new(pageviews: 'n/a', users: 'n/a', sessions: 'n/a')
      end

      def page_path(exhibit)
        path = if exhibit.is_a?(Spotlight::Exhibit)
                 Spotlight::Engine.routes.url_helpers.exhibit_path(exhibit)
               else
                 exhibit
               end

        "/os200#{path}"
      end

    end
  end
end