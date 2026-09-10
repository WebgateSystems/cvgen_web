# frozen_string_literal: true

class ThemeFileUploader < CarrierWave::Uploader::Base
  include UuidShardedStore

  storage :file

  def extension_allowlist
    %w[yml yaml]
  end

  def filename
    "#{model.slug.presence || 'theme'}.yaml"
  end

  private

  def store_kind
    "themes"
  end
end
