# frozen_string_literal: true

require "rails_helper"

RSpec.describe CvProfileFromAnalysis do
  let(:markdown) { Rails.root.join("spec/fixtures/files/cv-sample.md").read }

  it "sends the track name and analysis JSON to ChatGPT and saves a version" do
    profile = create(:user_profile, :analyzed)
    allow(ChatGpt).to receive(:new).and_return(instance_double(ChatGpt, call: markdown))

    record = described_class.new(profile, name: "Software Engineer").call

    expect(record.name).to eq("Software Engineer")
    expect(record.latest_version.person_name).to eq("Test Person")
    expect(record.latest_version.tag).to eq(I18n.t("jobseeker.profiles.from_account_tag"))
    expect(ChatGpt).to have_received(:new).with(
      hash_including(prompt: a_string_including("Software Engineer"))
    )
    expect(ChatGpt).to have_received(:new).with(
      hash_including(prompt: a_string_including("Analytical Engine"))
    )
  end

  it "raises when there is nothing to draft from" do
    profile = create(:user_profile, display_name: nil, about: nil, location: nil)
    expect { described_class.new(profile, name: "Designer").call }
      .to raise_error(CvProfileFromAnalysis::EmptyProfile)
  end

  it "raises when ChatGPT returns something that is not cvgen Markdown" do
    profile = create(:user_profile, :analyzed)
    allow(ChatGpt).to receive(:new).and_return(instance_double(ChatGpt, call: "not a cv"))

    expect { described_class.new(profile, name: "Designer").call }
      .to raise_error(CvProfileFromAnalysis::InvalidMarkdown)
  end
end
