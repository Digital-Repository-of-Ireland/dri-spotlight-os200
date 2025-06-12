##
# Global Spotlight helpers
module SpotlightHelper
  include ::BlacklightHelper
  include Spotlight::MainAppHelpers

  # create a link to a location name facet value
  # @param field_value [String] Solr field value
  # @param field [String] Solr field name
  # @param display_value [String] value to display instead of field_value
  def link_to_placename_field_spotlight(field_value, field, display_value = nil)
    new_params = if params[:f] && params[:f][field]&.include?(field_value)
                   search_state.params
                 else
                   search_state.add_facet_params(field, field_value)
                 end
    new_params[:view] = default_document_index_view_type
    new_params.except!(:id, :spatial_search_type, :coordinates, :controller, :action, :exhibit_id)
    link_to(display_value.presence || field_value, search_exhibit_catalog_path(new_params))
  end

  # create a link to a spatial search for a set of point coordinates
  # @param point_coords [Array]
  def link_to_point_search_spotlight(point_coords)
    new_params = params.except(:controller, :action, :view, :id, :spatial_search_type, :coordinates)
    new_params[:spatial_search_type] = 'point'
    new_params[:coordinates] = "#{point_coords[1]},#{point_coords[0]}"
    new_params[:view] = default_document_index_view_type
    new_params.permit!
    link_to(t('blacklight.maps.interactions.point_search'), search_exhibit_catalog_path(new_params))
  end
end
