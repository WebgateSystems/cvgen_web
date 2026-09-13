# frozen_string_literal: true

require "rails_helper"

RSpec.describe CvGenerator do
  let(:user) { create(:user, :jobseeker) }
  let(:profile) { create(:cv_profile, user: user, name: "Software Engineer") }
  let(:theme) { create(:theme) }
  let(:build) do
    CvBuild.new(
      user: user,
      cv_profile_id: profile.id,
      cv_profile_version_id: profile.latest_version.id,
      theme_id: theme.id,
      layout: "modern-stack",
      generator_profile: "default",
      include_skills: "Ruby, Rails",
      exclude: "cover-letter",
      max_experience_items: 3
    )
  end

  describe ".typst_available?" do
    it "returns true when typst reports success" do
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture3).with("typst", "--version").and_return([ "", "", status ])
      expect(described_class.typst_available?).to be(true)
    end

    it "returns false when typst is not installed" do
      allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)
      expect(described_class.typst_available?).to be(false)
    end
  end

  describe "#build_pdf" do
    it "raises when typst is missing" do
      allow(described_class).to receive(:typst_available?).and_return(false)
      expect { described_class.new(build).build_pdf }.to raise_error(CvGenerator::Error)
    end

    it "copies the workspace and returns the built PDF" do
      allow(described_class).to receive(:typst_available?).and_return(true)
      allow(Cvgen::Builder).to receive(:new) do |**kwargs|
        expect(kwargs[:root].join("content", "#{build.content_stem}.md")).to exist
        expect(kwargs[:root].join("themes", "#{theme.slug}.yaml")).to exist
        expect(kwargs[:root].join("profiles", "default.yaml")).to exist
        expect(kwargs[:root].join("layouts")).to exist
        pdf = kwargs[:root].join("out.pdf")
        File.write(pdf, "%PDF-1.4 generated")
        instance_double(Cvgen::Builder, build!: { pdf: pdf, pages: 2, scale: 1.0 })
      end

      result = described_class.new(build).build_pdf
      expect(result[:pdf]).to eq("%PDF-1.4 generated")
      expect(result[:pages]).to eq(2)
      expect(result[:filename]).to eq("software-engineer-v1.pdf")
    end

    it "wraps schema errors from the gem" do
      allow(described_class).to receive(:typst_available?).and_return(true)
      builder = instance_double(Cvgen::Builder)
      allow(Cvgen::Builder).to receive(:new).and_return(builder)
      allow(builder).to receive(:build!).and_raise(Cvgen::SchemaError, "bad schema")

      expect { described_class.new(build).build_pdf }.to raise_error(CvGenerator::Error, "bad schema")
    end
  end
end
