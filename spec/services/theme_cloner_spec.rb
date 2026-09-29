# frozen_string_literal: true

require "rails_helper"

RSpec.describe ThemeCloner do
  let(:user) { create(:user, :jobseeker) }
  let(:source) { create(:theme, name: "Modern Stack") }

  it "copies a system theme into a personal YAML theme" do
    theme = described_class.call(source: source, user: user)

    expect(theme).to be_personal
    expect(theme.user).to eq(user)
    expect(theme.name).to eq("Modern Stack (copy)")
    expect(theme.yaml_text).to include("fonts:")
    expect(ThemeYaml.scalar(theme.yaml_text, "name")).to eq("Modern Stack (copy)")
  end

  it "adds a suffix when the copy name is already taken" do
    described_class.call(source: source, user: user)
    second = described_class.call(source: source, user: user)

    expect(second.name).to eq("Modern Stack (copy) 2")
    expect(second.slug).to eq("modern-stack-copy-2")
  end
end
