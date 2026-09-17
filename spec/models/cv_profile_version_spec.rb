# frozen_string_literal: true

require "rails_helper"

RSpec.describe CvProfileVersion do
  it "labels versions with and without a tag" do
    profile = create(:cv_profile)
    first = profile.latest_version
    expect(first.label).to eq("v1")

    first.update!(tag: "  Acme  ")
    expect(first.reload.tag).to eq("Acme")
    expect(first.label).to eq("v1 · Acme")
  end

  it "reads the person name from valid markdown" do
    profile = create(:cv_profile)
    expect(profile.person_name).to eq("Test Person")
    expect(profile.latest_version.person_name).to eq("Test Person")
    expect(profile.latest_version.raw_markdown).to include("Test Person")
  end

  it "fills in a phone label so Typst layouts can compile" do
    file = Tempfile.new([ "cv-phones", ".md" ])
    file.write(<<~MD)
      ---
      name: Ada Lovelace
      phones:
        - "+44 7123 456789"
      ---

      # Summary
      Notes.
    MD
    file.flush

    profile = create(:cv_profile)
    version = profile.versions.create!(
      file: Rack::Test::UploadedFile.new(file.path, "text/markdown")
    )

    expect(version.raw_markdown).to include("label:")
    expect(version.raw_markdown).to include("+44 7123 456789")
  ensure
    file.close
    file.unlink
  end

  it "returns nil when parsed markdown raises a schema error" do
    version = create(:cv_profile).latest_version
    allow(Cvgen::Parser).to receive(:parse).and_raise(Cvgen::SchemaError, "bad")
    expect(version.person_name).to be_nil
  end

  it "returns nil when markdown is missing or invalid" do
    version = described_class.new
    expect(version.parsed_content).to be_nil
    expect(version.person_name).to be_nil

    profile = create(:cv_profile)
    version = profile.versions.new(file: invalid_markdown_upload)
    expect(version).not_to be_valid
    expect(version.errors[:file]).to be_present
  end

  it "keeps an explicit version number" do
    profile = create(:cv_profile)
    version = profile.versions.create!(
      number: 9,
      file: markdown_upload
    )
    expect(version.number).to eq(9)
  end
end
