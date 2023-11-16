##
# Simplified catalog controller
class CatalogController < ApplicationController
  include Blacklight::Catalog
  include BlacklightRangeLimit::ControllerOverride

 
  include BlacklightMaps::Controller
  
  before_action :access_token, only: [:index, :show]

  configure_blacklight do |config|
    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    config.show.partials.insert(1, :show_map)
    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: 'search',
      rows: 10,
      fl: '*'
    }

    config.document_solr_path = 'get'
    config.document_unique_id_param = 'ids'

    # solr field configuration for search results/index views
    #config.view.index.thumbnail_field = 'thumbnail_url_ssm'
    config.view.list.thumbnail_field = 'thumbnail_square_url_ssm'

    config.index.title_field = 'full_title_tesim'

    config.add_search_field 'all_fields', label: 'Everything'

    config.add_sort_field 'relevance', sort: 'score desc', label: 'Relevance'

    config.add_facet_field 'readonly_collection_ssim', label: 'Collection'
    config.add_facet_field 'readonly_creator_ssim', label: 'Creator', limit: true
    config.add_facet_field 'readonly_barony_ssim', label: 'Barony', limit: true
    config.add_facet_field 'readonly_county_ssim', label: 'County', limit: true
    config.add_facet_field 'readonly_townland_ssim', label: 'Townland', limit: true
    config.add_facet_field 'readonly_parish_ssim', label: 'Parish', limit: true
    #config.add_facet_field 'readonly_year_ssim', label: 'Year', limit: true
    config.add_facet_field 'dates_ssim', label: 'Dates', limit: true
    config.add_facet_field 'geojson_ssim', limit: -2, label: 'Coordinates', show: false
    config.add_facet_field 'placename_sim', limit: -2, label: 'Placename', show: false
    config.add_facet_field 'date_drsim', label: 'Year',
                       range: {
                         num_segments: 30,
                         assumed_boundaries: [1830, 1850],
                         segments: false,
                         maxlength: 4,
                         date: true,
                         min: 1830,
                         max: 1867
                       }, presenter: DateFacetFieldPresenter
    config.add_facet_fields_to_solr_request!

    config.add_field_configuration_to_solr_request!

    config.view.maps.coordinates_field = 'geospatial'
    config.view.maps.placename_property = 'placename'
    config.view.maps.tileurl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
    config.view.maps.mapattribution = 'Map data &copy; <a href="https://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>'
    config.view.maps.maxzoom = 18
    config.view.maps.show_initial_zoom = 5
    config.view.maps.facet_mode = 'geojson'
    config.view.maps.placename_field = 'placename_sim'
    config.view.maps.geojson_field = 'geojson_ssim'
    config.view.maps.search_mode = 'placename'
    config.view.maps.spatial_query_dist = 0.5

    # Set which views by default only have the title displayed, e.g.,
    # config.view.gallery.title_only_by_default = true
  end

  def access_token
   @access_token ||= ArcGisTokenGenerator.new.token
  end
end
