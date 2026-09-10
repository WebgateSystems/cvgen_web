# frozen_string_literal: true

class MarkdownFileUploader < CarrierWave::Uploader::Base
  include UuidShardedStore

  storage :file

  def extension_allowlist
    %w[md markdown]
  end

  def filename
    tag = model.tag.to_s.parameterize.presence
    tag ? "#{tag}.md" : "cv.md"
  end

  private

  def store_kind
    "documents"
  end
end
