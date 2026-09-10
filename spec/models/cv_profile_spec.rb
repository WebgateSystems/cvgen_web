# frozen_string_literal: true

require "rails_helper"

RSpec.describe CvProfile do
  it "numbers versions sequentially and keeps an optional tag" do
    profile = create(:cv_profile, name: "Manager")
    first = profile.latest_version

    second = profile.versions.create!(
      file: Rack::Test::UploadedFile.new(
        Rails.root.join("spec/fixtures/files/cv-sample.md"),
        "text/markdown"
      ),
      tag: "Initech"
    )

    expect(first.number).to eq(1)
    expect(first.tag).to be_nil
    expect(second.number).to eq(2)
    expect(second.tag).to eq("Initech")
    expect(profile.latest_version).to eq(second)
  end
end
