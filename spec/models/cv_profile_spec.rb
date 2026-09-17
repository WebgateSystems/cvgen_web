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
    expect(profile.person_name).to eq("Test Person")
  end

  it "requires a version on create" do
    profile = build(:cv_profile)
    profile.versions.clear
    expect(profile).not_to be_valid
    expect(profile.latest_version).to be_nil
    expect(profile.person_name).to be_nil
  end

  it "allows a queued ChatGPT draft without a version yet" do
    profile = build(:cv_profile, draft_status: "queued")
    profile.versions.clear
    expect(profile).to be_valid
    expect(profile.drafting?).to be(true)
  end
end
