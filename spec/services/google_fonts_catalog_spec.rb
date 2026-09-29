# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoogleFontsCatalog do
  it "includes Google Fonts and known system families" do
    families = described_class.families.map { |font| font["family"] }
    expect(families).to include("Roboto Condensed", "Helvetica Neue", "Libertinus Serif")
    expect(described_class.google_id("Roboto Condensed")).to eq("roboto-condensed")
    expect(described_class.google_id("Helvetica Neue")).to be_nil
  end
end
