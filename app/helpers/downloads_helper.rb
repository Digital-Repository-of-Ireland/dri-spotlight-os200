module DownloadsHelper

  def iiif_url_to_download iiif
    ids = iiif.split('/')[4]
    obj_id,file_id = ids.split(':')

    "https://repository.dri.ie/objects/#{obj_id}/files/#{file_id}/download?type=surrogate"
  end

end