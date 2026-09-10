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
  end
end
