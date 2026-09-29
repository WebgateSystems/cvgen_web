# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoogleFontFiles do
  let(:root) { Pathname(Dir.mktmpdir) }
  let(:cache) { root.join("cache") }

  around do |example|
    previous = ENV["CVGEN_FONT_CACHE"]
    ENV["CVGEN_FONT_CACHE"] = cache.to_s
    example.run
  ensure
    ENV["CVGEN_FONT_CACHE"] = previous
    FileUtils.remove_entry(root)
  end

  it "downloads a catalog Google Font into the workspace" do
    allow(described_class).to receive(:fetch).and_return(nil)
    allow(described_class).to receive(:fetch)
      .with(/roboto-condensed@latest\/latin-400-normal\.ttf/)
      .and_return("ttf-400")

    described_class.new(
      root,
      "fonts" => { "heading" => "Roboto Condensed", "body" => "Helvetica Neue" }
    ).prepare!

    expect(root.join("fonts/roboto-condensed/latin-400-normal.ttf").read).to eq("ttf-400")
    expect(root.join("fonts/helvetica-neue")).not_to exist
  end
end
