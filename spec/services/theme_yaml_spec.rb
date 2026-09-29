# frozen_string_literal: true

require "rails_helper"

RSpec.describe ThemeYaml do
  let(:yaml) do
    <<~YAML
      name: modern-stack
      fonts:
        heading: "Helvetica Neue"
        body: Helvetica Neue
    YAML
  end

  it "reads and patches name and font scalars" do
    expect(described_class.scalar(yaml, "heading")).to eq("Helvetica Neue")
    expect(described_class.scalar(yaml, "body")).to eq("Helvetica Neue")

    patched = described_class.patch(
      yaml,
      name: "Modern Stack (copy)",
      heading: "Roboto Condensed",
      body: "Roboto Condensed"
    )

    expect(patched).to include('name: "Modern Stack (copy)"')
    expect(patched).to include('heading: "Roboto Condensed"')
    expect(patched).to include('body: "Roboto Condensed"')
  end
end
