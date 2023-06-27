# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  include Blacklight::Gallery::OpenseadragonSolrDocument

  include Spotlight::SolrDocument

  include Spotlight::SolrDocument::AtomicUpdates


  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  POINT_KEYS = %w[east north].freeze
  PROJECTIONS = { 'itm' => '2157', 'ing' => '29903' }.freeze

  def parse_dcmi_point(geospatial_string)
      result = {}

      begin
        point = dcmi_components(geospatial_string)
      rescue => e
        Rails.logger.error("Exception in transform_geospatial: #{geospatial_string} => #{e}")
        return result
      end

      # [east_long north_lat]
      if supported_dcmi?(POINT_KEYS, point)
        if point['projection'].present? && PROJECTIONS.keys.include?(point['projection'].downcase)
         projection = PROJECTIONS[point['projection'].downcase]

         geometry_crs = { crs: "http://www.opengis.net/def/crs/EPSG/0/#{projection}" }
         geometry_crs[:coordinates] = [point['east'].delete(',').to_f, point['north'].delete(',').to_f]
        end
                 
        coords = "#{point['east']} #{point['north']}"
        return result if coords.blank?

        result[:coords] = coords
        result[:name] = point['name']
        result[:json] = coords_to_geojson([point['name']], coords, geometry_crs)
      end

      result
    end

    def dcmi_components(value = nil)
      return {} if value.nil?

      dcmi_components = {}

      value.split(/\s*;\s*/).each do |component|
        (k, v) = component.split(/\s*=\s*/)
        dcmi_components[k.downcase] = v.strip
      end

      dcmi_components
    end

    def supported_dcmi?(key_array = [], hash = {})
      key_array.all? { |s| hash.key? s }
    end

    # Transforms a geocode into a Geo Json Hash
    # @param [String] name the displayable place name for a geocode value
    # @param [String] coords the string including the coordinates for a geocode value
    # @return [Hash] the hash including the geocode value formatted in GEO Json
    def coords_to_geojson(name, coords, geometry_crs = nil, uri = nil)
      geojson_hash = { type: 'Feature', geometry: {}, properties: {} }

      if coords.scan(/[\s]/).length == 3
        # bbox
        coords_array = coords.split(' ').map(&:to_f)
        geojson_hash[:bbox] = coords_array
        geojson_hash[:geometry][:type] = 'Polygon'
        geojson_hash[:geometry][:coordinates] = [[[coords_array[0], coords_array[1]],
                                                  [coords_array[2], coords_array[1]],
                                                  [coords_array[2], coords_array[3]],
                                                  [coords_array[0], coords_array[3]],
                                                  [coords_array[0], coords_array[1]]]]
      elsif coords.match(/^[-]?[\d]*[\.]?[\d]*[ ,][-]?[\d]*[\.]?[\d]*$/)
        # point
        geojson_hash[:geometry][:type] = 'Point'

        coords_array = if coords.match(/,/)
                         coords.split(',').reverse
                       else
                         coords.split(' ')
                       end

        geojson_hash[:geometry][:coordinates] = coords_array.map(&:to_f)
      else
        Rails.logger.error("This coordinate format is not yet supported: '#{coords}'")
      end

      geojson_hash[:properties] = {}
      geojson_hash[:properties][:placename] = name if name.present?
      geojson_hash[:properties][:geometryCRS] = geometry_crs unless geometry_crs.nil?
      geojson_hash[:properties][:uri] = uri unless uri.blank?
      
      # Return as a JSON String for blacklight-maps
      geojson_hash
    end
end
