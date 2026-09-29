# frozen_string_literal: true

require "rails_helper"

RSpec.describe Company do
  it "requires an official name, a country, and at least one identifier" do
    company = build(:company, official_name: "", country: nil)
    company.identifiers.clear

    expect(company).not_to be_valid
    expect(company.errors[:official_name]).to be_present
    expect(company.errors[:identifiers]).to be_present
    expect(company.errors[:country]).to be_present
  end

  it "does not treat official_name as unique" do
    create(:company, official_name: "Google", shortcut: "Google PL", country: "PL",
           identifiers_attributes: [ { kind: "nip", value: "5250000001" } ])
    twin = build(:company, official_name: "Google", shortcut: "Google IE", country: "IE",
                 identifiers_attributes: [ { kind: "vat_eu", value: "IE1234567T" } ])

    expect(twin).to be_valid
  end

  it "enforces uniqueness of identifier kind and value" do
    create(:company, country: "PL", identifiers_attributes: [ { kind: "nip", value: "5252344078" } ])
    duplicate = build(:company, country: "PL", identifiers_attributes: [ { kind: "nip", value: "525-234-40-78" } ])

    expect(duplicate).not_to be_valid
    expect(duplicate.identifiers.first.errors[:value]).to be_present
  end

  it "strips separators from the identifier" do
    company = create(:company, identifiers_attributes: [ { kind: "nip", value: "525-234-40-78" } ])
    expect(company.identifiers.first.value).to eq("5252344078")
  end

  it "averages overall ratings to one decimal" do
    company = create(:company)
    create(:company_rating, company: company, user: create(:user),
           responsiveness: 4, seriousness: 4, human_process: 4, fairness: 4)
    create(:company_rating, company: company, user: create(:user),
           responsiveness: 5, seriousness: 5, human_process: 5, fairness: 5)

    company.reload
    expect(company.overall_rating).to eq(4.5)
    expect(company.formatted_rating).to eq("4.5")
  end

  it "searches name, shortcut, and identifier from two characters" do
    create(:company, shortcut: "YND", official_name: "YND Sp. z o.o.",
           identifiers_attributes: [ { kind: "nip", value: "5252344078" } ])
    create(:company, shortcut: "Acme", official_name: "Acme Platform",
           identifiers_attributes: [ { kind: "nip", value: "1112223334" } ])

    expect(described_class.search_text("Y").pluck(:shortcut)).to contain_exactly("YND", "Acme")
    expect(described_class.search_text("YND").pluck(:shortcut)).to eq(%w[YND])
    expect(described_class.search_text("525234").pluck(:shortcut)).to eq(%w[YND])
  end
end
