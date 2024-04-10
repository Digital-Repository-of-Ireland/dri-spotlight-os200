module Spotlight
  module Resources
    ##
    # A PORO to construct a solr hash for a given Dri Object json
    class DriObject
      attr_reader :collection
      def initialize(attrs = {})
        @id = attrs[:id]
        @metadata = attrs[:metadata]
        @files = attrs[:files]
        @solr_hash = {}
      end

      def to_solr(exhibit:)
        with_exhibit(exhibit)

        add_document_id
        add_depositing_institute
        add_label
        add_creator
        add_author
        #add_year
        add_date_range('creation_date')
        add_date_range('date')

        if metadata.key?('subject') && metadata['subject'].present?
          add_subject_facet
          add_type_facet
        end

        add_collection_facet
        add_temporal_coverage
        add_geographical_coverage
        add_metadata
        add_collection_id
        add_relation

        add_image_urls if metadata['type'] != ['Collection']
        add_thumbnail
        add_iiif_manifest

        solr_hash
      end

      def with_exhibit(e)
        @exhibit = e
      end

      def compound_id(id)
        Digest::MD5.hexdigest("#{exhibit.id}-#{id}")
      end

      private

      attr_reader :id, :exhibit, :metadata, :files, :solr_hash
      delegate :blacklight_config, to: :exhibit

      def add_creator
        solr_hash['readonly_creator_ssim'] = metadata['creator']
      end

      def add_author
        return unless metadata.key?('role_aut') && metadata['role_aut'].present?
        solr_hash['readonly_author_ssim'] = metadata['role_aut']
      end

      def add_depositing_institute
        if metadata.key?('institute')
          metadata['institute'].each do |institute|
            if institute['depositing'] == true
              solr_hash['readonly_depositing_institute_tesim'] = institute['name']
            end
          end
        end
      end

      def add_subject_facet
        solr_hash['readonly_subject_ssim'] = metadata['subject']
      end

      def add_temporal_coverage
        return unless metadata.key?('temporal_coverage') && metadata['temporal_coverage'].present?
        solr_hash['readonly_temporal_coverage_ssim'] = dri_object.dcmi_name(metadata['temporal_coverage'])
      end

      def add_thumbnail
        files.each do |file|
          # skip unless it is an image
          next unless file && file.key?(surrogate_postfix)

          file_id = file_id_from_uri(file[surrogate_postfix])

          solr_hash[thumbnail_field] = "#{iiif_manifest_base}/#{id}:#{file_id}/full/!400,400/0/default.jpg"
          solr_hash[thumbnail_list_field] = "#{iiif_manifest_base}/#{id}:#{file_id}/square/100,100/0/default.jpg"
          break
        end
      end

      def add_iiif_manifest
        solr_hash['iiif_manifest_url_ssi'] = "#{repository_iiif_base}/#{id}/manifest.json"
      end

      def add_geographical_coverage
        return unless metadata.key?('geographical_coverage') && metadata['geographical_coverage'].present?
        solr_hash['readonly_geographical_coverage_ssim'] = metadata['geographical_coverage']

        points = { coords: [], name: [], json: [] }
        metadata['geographical_coverage'].each do |point| 
          parsed_point = dri_object.parse_dcmi_point(point)

          points[:coords] << parsed_point[:coords] if parsed_point[:coords].present?
          points[:name] << parsed_point[:name] if parsed_point[:name].present?
          points[:json] << parsed_point[:json]
        end
        solr_hash["geospatial"] = points[:coords] if points[:coords].present?
        if points[:name].present?
          solr_hash["placename_tesim"] = points[:name]
          solr_hash["placename_sim"] = points[:name]
        end

        if points[:json].present?
          solr_hash["geojson_ssim"] = points[:json]
        end

        solr_hash['readonly_barony_ssim'] = dri_object.barony
        solr_hash['readonly_county_ssim'] = dri_object.county
        solr_hash['readonly_townland_ssim'] = dri_object.townland
        solr_hash['readonly_parish_ssim'] = dri_object.parish
        solr_hash['readonly_county_tesim'] = dri_object.county
        solr_hash['readonly_townland_tesim'] = dri_object.townland
        solr_hash['readonly_parish_tesim'] = dri_object.parish
      end

      def add_type_facet
        solr_hash['readonly_type_ssim'] = metadata['type'].map(&:strip)
      end

      def add_document_id
        solr_hash['readonly_dri_id_ssim'] = id
        solr_hash[blacklight_config.document_model.unique_key.to_sym] = compound_id(id)
      end

      def add_collection_id
        if metadata.key?('isGovernedBy')
          solr_hash[collection_id_field] = [compound_id(metadata['isGovernedBy'])]
        end
      end

      def add_collection_facet
        solr_hash['readonly_collection_ssim'] = dri_object.collection
      end

      def collection_id_field
        :collection_id_ssim
      end

      def add_image_urls
        solr_hash[tile_source_field] = image_urls
      end

      def add_label
        return unless title_field && metadata.key?('title')
        solr_hash[title_field] = metadata['title']
      end

      def add_date_range(date_type)
        return unless metadata.key?(date_type) && metadata[date_type].present?

        date = metadata[date_type].first
        parsed_date = dri_object.parse_dcmi_date(date)

        range_start = parsed_date[:start] if parsed_date.key?(:start)
        range_end = parsed_date[:end] if parsed_date.key?(:end)
 
        solr_hash["date_drsim"] = if range_start && range_end
                                    "[#{range_start} TO #{range_end}]"
                                  elsif range_start
                                    range_start
                                  elsif range_end
                                    range_end
                                  end

        if parsed_date.key?(:name)
          if solr_hash.key?('dates_ssim')
            solr_hash['dates_ssim'] << parsed_date[:name]
          else
            solr_hash['dates_ssim'] = parsed_date[:name]
          end
        end
      end

      def add_year
        return unless metadata.key?('creation_date') && metadata['creation_date'].present?
        solr_hash['readonly_year_ssim'] = dri_object.year
      end

      def add_metadata
        solr_hash.merge!(object_metadata)
        sidecar.update(data: sidecar.data.merge(object_metadata))
      end

      def add_relation
        return unless metadata.key?('ext_related_items_ids_relation') && metadata['ext_related_items_ids_relation'].present?
        solr_hash['readonly_relation_ssim'] = metadata['ext_related_items_ids_relation']
      end

      def object_metadata
        return {} unless metadata.present?
        item_metadata = dri_object.to_solr

        create_sidecars_for(*item_metadata.keys)

        item_metadata.each_with_object({}) do |(key, value), hash|
          next unless (field = exhibit_custom_fields[key])
          hash[field.field] = value
        end
      end

      def dri_object
        @dri_object ||= metadata_class.new(metadata)
      end

      def create_sidecars_for(*keys)
        missing_keys(keys).each do |k|
          exhibit.custom_fields.create! label: k, readonly_field: true
        end
        @exhibit_custom_fields = nil
      end

      def missing_keys(keys)
        custom_field_keys = exhibit_custom_fields.keys.map(&:downcase)
        keys.reject do |key|
          custom_field_keys.include?(key.downcase)
        end
      end

      def exhibit_custom_fields
        @exhibit_custom_fields ||= exhibit.custom_fields.each_with_object({}) do |value, hash|
          hash[value.configuration['label']] = value
        end
      end

      def iiif_manifest_base
        Spotlight::Resources::Dri::Engine.config.iiif_manifest_base
      end

      def repository_iiif_base
        Rails.configuration.repository_iiif_base
      end

      def image_urls
        @image_urls ||= files.map do |file|
          # skip unless it is an image
          next unless file && file.key?(surrogate_postfix)

          file_id = file_id_from_uri(file[surrogate_postfix])

          "#{iiif_manifest_base}/#{id}:#{file_id}/info.json"
        end.compact
      end

      def file_id_from_uri(uri)
        File.basename(URI.parse(uri).path).split("_")[0]
      end

      def thumbnail_field
        blacklight_config.index.try(:thumbnail_field)
      end

      def thumbnail_list_field
        blacklight_config.view.list.try(:thumbnail_field)
      end

      def tile_source_field
        blacklight_config.show.try(:tile_source_field)
      end

      def title_field
        blacklight_config.index.try(:title_field)
      end

      def sidecar
        @sidecar ||= document_model.new(id: compound_id(id)).sidecar(exhibit)
      end

      def surrogate_postfix
        Spotlight::Resources::Dri::Engine.config.surrogate_postfix
      end

      def document_model
        exhibit.blacklight_config.document_model
      end

      def metadata_class
        Spotlight::Resources::DriObject::Metadata
      end

      ###
      #  A simple class to map the metadata field
      #  in an object to label/value pairs
      #  This is intended to be overriden by an
      #  application if a different metadata
      #  strucure is used by the consumer
      class Metadata
        def initialize(metadata)
          @metadata = metadata
        end

        def to_solr
          metadata_hash.merge(descriptive_metadata)
        end

        def ancestor_titles
          return unless metadata.key?('ancestor_title') && metadata['ancestor_title'].present?
          @ancestor_titles ||= metadata['ancestor_title']
        end

        def collection
          return if ancestor_titles.blank?

          root_title = ancestor_titles.last.downcase
          case root_title
          when 'ordnance survey of ireland letters'
            'OS Letters'
          when 'ordnance survey first edition 6-inch map sheet information'
            'OS Maps'
          when 'ordnance survey name book transcriptions'
            'OS Name Books'
          when 'ordnance survey memoir drawings'
            'OS Drawings'
          when 'ordnance survey memoirs'
            'OS Memoirs'
          end
        end

        def dcmi_name(value)
          value.map do |v|
            name = v[/\Aname=(?<name>.+?);/i, 'name']
            name.try(:strip) || v
          end
        end

        def author
          metadata['role_aut'] unless metadata.key?('role_aut') && metadata['role_aut'].present?
        end

        def barony
          region('barony')
        end

        def county
          region('county')
        end

        def parish
          region('parish')
        end

        def townland
          t = region('townland')
          return if t.blank?

          dcmi_name(t)
        end

        def region(key)
          return unless metadata.key?('geographical_coverage') && metadata['geographical_coverage'].present?
          r = metadata['geographical_coverage'].select { |s| dcmi_name([s]).first.downcase.include?(key) }
          return if r.empty?

          r
        end

        def parse_dcmi_date(date)
          results = {}
          return results[:name] = date if !date.include?('name')

          date.split(/\s*;\s*/).each do |component|
            (k,v) = component.split(/\s*=\s*/)
            if k == "name"
              results[:name] = v
            else
              begin
                results[k.to_sym] = Date.parse(v).year
              rescue Date::Error
                next
              end
            end
          end

          results
        end

        def year
          return unless metadata.key?('creation_date') && metadata['creation_date'].present?
          cdate = metadata['creation_date'].first

          start = if cdate.include?('name=')
                    results = parse_dcmi_date(cdate)
                    results[:start] || results[:end] || results[:name]
                  else
                    cdate
                  end

          begin
            Time.parse(start).year
          rescue
            nil
          end
        end

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
              dcmi_components[k.downcase] = v.strip unless v.nil?
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
            geojson_hash.to_json.to_s
          end

        private

        attr_reader :metadata

        def metadata_hash
          return {} unless metadata.present?
          return {} unless metadata.is_a?(Array)

          metadata.each_with_object({}) do |md, hash|
            next unless md['label'] && md['value']
            hash[md['label']] ||= []
            hash[md['label']] += Array(md['value'])
          end
        end

        def descriptive_metadata
          desc_metadata_fields.each_with_object({}) do |field, hash|
            case field
            when 'attribution'
              add_attribution(field, hash)
              next
            when 'temporal_coverage'
              add_dcmi_field(field, hash)
              next
            when 'geographical_coverage'
              add_dcmi_field(field, hash)
              next
            when 'barony'
              add_barony(field, hash)
              next
            when 'collection'
              add_collection(field, hash)
              next
            when 'county'
              add_county(field, hash)
              next
            when 'parish'
              add_parish(field, hash)
              next
            when 'townland'
              add_townland(field, hash)
              next
            when 'doi'
              add_doi(field, hash)
              next
            when 'year'
              add_year(field, hash)
              next
            when 'ext_related_items_ids_relation'
              hash['Relation'] ||= []
              hash['Relation'] += Array(metadata[field])
              next
            end

            next unless metadata[field].present?
            hash[field.capitalize] ||= []
            hash[field.capitalize] += Array(metadata[field])
          end
        end

        def desc_metadata_fields
          %w(description doi creator author year subject ext_related_items_id_relation barony county townland parish collection geographical_coverage temporal_coverage type attribution rights license)
        end

        def add_attribution(field, hash)
          return unless metadata.key?('institute')

          hash[field.capitalize] ||= []
          metadata['institute'].each do |institute|
            hash[field.capitalize] += Array(institute['name'])
          end
        end

        def add_author(field, hash)
          hash[field.capitalize] ||= []
          hash[field.capitalize] = author
        end

        def add_year(field, hash)
          hash[field.capitalize] ||= []
          hash[field.capitalize] = year
        end

        def add_doi(field, hash)
          if metadata['doi'].present? && metadata['doi'].first.key?('url')
            hash[field.capitalize] = metadata['doi'].first['url']
          end
        end

        def add_barony(field, hash)
          hash[field.capitalize] ||= []
          hash[field.capitalize] = barony
        end

        def add_collection(field, hash)
          hash[field.capitalize] ||= []
          hash[field.capitalize] = collection
        end

        def add_county(field, hash)
          hash[field.capitalize] ||= []
          hash[field.capitalize] = county
        end

        def add_parish(field, hash)
          hash[field.capitalize] ||= []
          hash[field.capitalize] = parish
        end

        def add_townland(field, hash)
          hash[field.capitalize] ||= []
          hash[field.capitalize] = townland
        end

        def add_dcmi_field(field, hash)
          return unless metadata.key?(field)
          hash[field.capitalize] ||= []
          hash[field.capitalize] = dcmi_name(metadata[field])
        end
      end
    end
  end
end
