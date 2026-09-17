# frozen_string_literal: true

class AvatarUploader < CarrierWave::Uploader::Base
  include UuidShardedStore

  storage :file

  def extension_allowlist
    %w[jpg jpeg png webp gif]
  end

  def size_range
    1..(5.megabytes)
  end

  def filename
    return unless original_filename

    "avatar#{File.extname(original_filename).downcase}"
  end

  private

  def store_kind
    "avatars"
  end
end
