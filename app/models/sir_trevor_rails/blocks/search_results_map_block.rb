# frozen_string_literal: true
module SirTrevorRails
  module Blocks
    ##
    # Map display of documents
    class SearchResultsMapBlock < SirTrevorRails::Blocks::SearchResultsBlock

      def geojson_features(documents_list)
        "{ \"type\": \"FeatureCollection\", \"features\": [ #{features(documents_list)} ] }"
      end

      def access_token
        @access_token ||= ArcGisTokenGenerator.new.token
      end

      def features(document_list)
        features = ""
        document_list.each do |doc|
          features += doc[:geojson_ssim].join(',')
        end

        features
      end
    end
  end
end
