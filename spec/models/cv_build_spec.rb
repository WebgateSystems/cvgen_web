# frozen_string_literal: true

require "rails_helper"

RSpec.describe CvBuild do
  it "builds a CLI command from the selected generator flags" do
    user = create(:user, :jobseeker)
    profile = create(:cv_profile, user: user, name: "Software Engineer")
    theme = create(:theme, name: "Modern Blue")
    build = described_class.new(
      user: user,
      cv_profile_id: profile.id,
      cv_profile_version_id: profile.latest_version.id,
      theme_id: theme.id,
      layout: "modern-stack",
      generator_profile: "default",
      scale: 0.95,
      fit: true
    )

    expect(build).to be_valid
    expect(build.content_stem).to eq("software-engineer-v1")
    expect(build.cli_command).to include("-c software-engineer-v1")
    expect(build.cli_command).to include("-p default")
    expect(build.cli_command).to include("-l modern-stack")
    expect(build.cli_command).to include("-t modern-blue")
    expect(build.cli_command).to include("--scale 0.95")
    expect(build.cli_command).to include("--fit")
    expect(build.pdf_filename).to eq("software-engineer-v1.pdf")
  end

  it "validates ownership, availability, and catalog names" do
    user = create(:user, :jobseeker)
    foreign = create(:cv_profile)
    theme = create(:theme, :personal, user: create(:user, :jobseeker))
    build = described_class.new(
      user: user,
      cv_profile_id: foreign.id,
      cv_profile_version_id: foreign.latest_version.id,
      theme_id: theme.id,
      layout: "does-not-exist",
      generator_profile: "missing"
    )

    expect(build).not_to be_valid
    expect(build.errors[:cv_profile_version_id]).to be_present
    expect(build.errors[:theme_id]).to be_present
    expect(build.errors[:layout]).to be_present
    expect(build.errors[:generator_profile]).to be_present
  end

  it "builds a profile payload and falls back without a selected profile" do
    user = create(:user, :jobseeker)
    profile = create(:cv_profile, user: user)
    theme = create(:theme)
    build = described_class.new(
      user: user,
      cv_profile_id: profile.id,
      cv_profile_version_id: profile.latest_version.id,
      theme_id: theme.id,
      include_skills: "Ruby, Rails",
      exclude: "Acme\nGlobex",
      max_experience_items: 4
    )

    expect(build.profile_payload).to include(
      "max_experience_items" => 4,
      "exclude" => %w[Acme Globex]
    )
    expect(build.profile_payload.dig("include", "skills")).to eq(%w[Ruby Rails])

    empty = described_class.new
    expect(empty.content_stem).to eq("cv")
    expect(empty.cli_command).to include("-t THEME")
    expect(empty.profile).to be_nil
    expect(empty.theme).to be_nil
  end
end
