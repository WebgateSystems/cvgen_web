# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatGpt::Prompt do
  it "loads a prompt file from config/prompts" do
    text = described_class.load("cv_analysis")
    expect(text).to include("ONLY valid JSON")
    expect(text).to include("person_name")
    expect(text).to include("contact")
    expect(text).to include("phones")
    expect(text).to include("level")
  end

  it "loads the career-track profile prompt" do
    text = described_class.load("cv_profile")
    expect(text).to include("career track")
    expect(text).to include("Essential Skills")
    expect(text).to include("BOTH keys")
  end

  it "raises when the prompt file is missing" do
    expect { described_class.load("does_not_exist") }.to raise_error(ChatGpt::Prompt::Missing, /does_not_exist/)
  end
end
