# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyMatch do
  it "treats the same name, country, and identifier as one company" do
    existing = create(:company, official_name: "YND Sp. z o.o.", country: "PL",
                      identifiers_attributes: [ { kind: "nip", value: "5252344078" } ])

    found = described_class.call(
      "official_name" => "YND Sp. z o.o.",
      "country" => "PL",
      "identifiers" => [ { "kind" => "nip", "value" => "525-234-40-78" } ]
    )

    expect(found).to eq(existing)
  end

  it "does not match the same name when the identifier belongs to another country" do
    create(:company, official_name: "Google", country: "PL",
           identifiers_attributes: [ { kind: "nip", value: "5250000001" } ])

    found = described_class.call(
      "official_name" => "Google",
      "country" => "IE",
      "identifiers" => [ { "kind" => "vat_eu", "value" => "IE1234567T" } ]
    )

    expect(found).to be_nil
  end

  it "matches a different spelling when any identifier is the same" do
    existing = create(:company, official_name: "YND Sp. z o.o.", country: "PL",
                      identifiers_attributes: [
                        { kind: "nip", value: "5252344078" },
                        { kind: "krs", value: "0000123456" }
                      ])

    found = described_class.call(
      "official_name" => "YND spółka z ograniczoną odpowiedzialnością",
      "country" => "PL",
      "identifiers" => [ { "kind" => "krs", "value" => "0000123456" } ]
    )

    expect(found).to eq(existing)
  end
end
