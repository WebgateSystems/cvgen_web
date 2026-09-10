# frozen_string_literal: true

require "rails_helper"

RSpec.describe UuidShardedStore do
  UUID = "3fa85f64-5717-4562-b3fc-2c963f66afa6"

  it "places markdown CVs under a sharded documents tree" do
    version = CvProfileVersion.new(id: UUID)
    uploader = MarkdownFileUploader.new(version, :file)

    expect(uploader.store_dir).to eq("uploads/documents/3f/a8/#{UUID}")
  end

  it "places themes under a sharded themes tree" do
    theme = Theme.new(id: UUID)
    uploader = ThemeFileUploader.new(theme, :file)

    expect(uploader.store_dir).to eq("uploads/themes/3f/a8/#{UUID}")
  end
end
