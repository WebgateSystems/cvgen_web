# frozen_string_literal: true

require "rails_helper"

RSpec.describe Company do
  it "requires an official name and a legal identity" do
    company = build(:company, official_name: "", legal_id: "", country: nil)
    expect(company).not_to be_valid
    expect(company.errors[:official_name]).to be_present
    expect(company.errors[:legal_id]).to be_present
    expect(company.errors[:country]).to be_present
  end

  it "does not treat official_name as unique" do
    create(:company, official_name: "Google", shortcut: "Google PL", country: "PL", legal_id: "5250000001")
    twin = build(:company, official_name: "Google", shortcut: "Google IE", country: "IE", legal_id: "IE1234567T")
    expect(twin).to be_valid
  end

  it "enforces uniqueness of country + legal id kind + legal id" do
    create(:company, country: "PL", legal_id_kind: :nip, legal_id: "5252344078")
    duplicate = build(:company, country: "PL", legal_id_kind: :nip, legal_id: "525-234-40-78")
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:legal_id]).to be_present
  end

  it "strips separators from the legal id" do
    company = create(:company, legal_id: "525-234-40-78")
    expect(company.legal_id).to eq("5252344078")
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

  it "searches name, shortcut, and legal id from two characters" do
    create(:company, shortcut: "YND", official_name: "YND Sp. z o.o.", legal_id: "5252344078")
    create(:company, shortcut: "Acme", official_name: "Acme Platform", legal_id: "1112223334")

    expect(described_class.search_text("Y").pluck(:shortcut)).to contain_exactly("YND", "Acme")
    expect(described_class.search_text("YND").pluck(:shortcut)).to eq(%w[YND])
    expect(described_class.search_text("525234").pluck(:shortcut)).to eq(%w[YND])
  end
end
