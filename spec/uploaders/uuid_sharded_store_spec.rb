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

  it "places avatars under a sharded avatars tree" do
    profile = UserProfile.new(id: UUID)
    uploader = AvatarUploader.new(profile, :avatar)

    expect(uploader.store_dir).to eq("uploads/avatars/3f/a8/#{UUID}")
  end

  it "falls back to 00 shards when the id has no hex" do
    model = Struct.new(:id).new("")
    uploader = ThemeFileUploader.new(model, :file)

    expect(uploader.store_dir).to eq("uploads/themes/00/00/")
  end

  it "requires store_kind" do
    klass = Class.new do
      include UuidShardedStore
      attr_reader :model

      def initialize(model)
        @model = model
      end
    end

    expect { klass.new(Theme.new(id: UUID)).store_dir }.to raise_error(NotImplementedError)
  end

  it "names uploaded files from slug and tag" do
    theme = Theme.new(id: UUID, slug: "modern-blue")
    expect(ThemeFileUploader.new(theme, :file).filename).to eq("modern-blue.yaml")

    version = CvProfileVersion.new(id: UUID, tag: "Acme")
    expect(MarkdownFileUploader.new(version, :file).filename).to eq("acme.md")
    expect(MarkdownFileUploader.new(CvProfileVersion.new(id: UUID), :file).filename).to eq("cv.md")
  end
end
