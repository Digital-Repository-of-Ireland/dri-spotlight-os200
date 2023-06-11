##
# Simplified catalog controller
class CatalogController < ApplicationController
  include Blacklight::Catalog

  configure_blacklight do |config|
    config.show.oembed_field = :oembed_url_ssm
    config.show.partials.insert(1, :oembed)

    config.view.gallery.partials = [:index_header, :index]
    config.view.masonry.partials = [:index]
    config.view.slideshow.partials = [:index]

    config.index.thumbnail_method = :render_thumbnail

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
    config.view.index.thumbnail_field = 'thumbnail_url_ssm'
    config.view.list.thumbnail_field = 'thumbnail_square_url_ssm'

    config.index.title_field = 'full_title_tesim'

    config.add_search_field 'all_fields', label: 'Everything'

    config.add_sort_field 'relevance', sort: 'score desc', label: 'Relevance'

    config.add_facet_field 'readonly_collection_ssim', label: 'Collection'
    config.add_facet_field 'readonly_author_ssim', label: 'Author', limit: true
    config.add_facet_field 'readonly_barony_ssim', label: 'Barony', limit: true
    config.add_facet_field 'readonly_county_ssim', label: 'County', limit: true
    config.add_facet_field 'readonly_townland_ssim', label: 'Townland', limit: true
    config.add_facet_field 'readonly_parish_ssim', label: 'Parish', limit: true
    config.add_facet_field 'readonly_year_ssim', label: 'Year', limit: true
    config.add_facet_fields_to_solr_request!

    config.add_field_configuration_to_solr_request!

    # Set which views by default only have the title displayed, e.g.,
    # config.view.gallery.title_only_by_default = true
  end
end
