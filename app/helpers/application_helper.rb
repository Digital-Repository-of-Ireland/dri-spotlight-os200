module ApplicationHelper

  include SpotlightHelper

  def render_thumbnail(document, options)
    return unless document['full_image_url_ssm'].present?

    url_parts = document['full_image_url_ssm'].first.split('full')
    image_tag(
      url_parts[0] + 'full/200,' + url_parts.last,
      options.merge(alt: presenter(document).document_heading)
    )
  end

end
