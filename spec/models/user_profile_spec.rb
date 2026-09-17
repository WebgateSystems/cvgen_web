# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserProfile do
  it "belongs to one user and starts with a blank analysis" do
    profile = create(:user_profile, display_name: "Ada")
    expect(profile.user).to be_present
    expect(profile.analysis_hash["skills"]).to eq([])
    expect(profile.experience_for_form).to eq([])
    expect(profile.languages_for_form).to eq([])
    expect(profile.analysis_present?).to be(false)
    expect(profile.cv_source_present?).to be(true)
  end

  it "stores a ChatGPT payload and fills a blank display name" do
    profile = create(:user_profile, display_name: nil, about: nil, location: nil)
    profile.apply_analysis!(
      "person_name" => "Ada Lovelace",
      "headline" => "Mathematician",
      "skills" => [ "Mathematics" ]
    )

    expect(profile.reload.display_name).to eq("Ada Lovelace")
    expect(profile.analyzed_at).to be_present
    expect(profile.analysis["headline"]).to eq("Mathematician")
    expect(profile.analysis_present?).to be(true)
  end

  it "does not overwrite an existing display name from analysis" do
    profile = create(:user_profile, display_name: "A.L.")
    profile.apply_analysis!("person_name" => "Ada Lovelace")
    expect(profile.display_name).to eq("A.L.")
  end

  it "is not a CV source when about-me and analysis are empty" do
    profile = create(:user_profile, display_name: nil, about: nil, location: nil)
    expect(profile.cv_source_present?).to be(false)
  end
end
