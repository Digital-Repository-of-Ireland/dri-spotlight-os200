# frozen_string_literal: true

module Spotlight
  ##
  # Sir-trevor image widget uploads
  class AttachmentUploader < CarrierWave::Uploader::Base
    storage Spotlight::Engine.config.uploader_storage

    # Override the directory where uploaded files will be stored.
    # This is a sensible default for uploaders that are meant to be mounted:
    def store_dir
      "#{Spotlight::Engine.config.uploader_storage_path}/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end
  end
end
