# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationFromOffer do
  let(:lookup) do
    ApplicationLookup.create!(
      user: create(:user, :jobseeker),
      source_url: "https://jobs.example/rails",
      status: "queued"
    )
  end
  let(:page) do
    CompanyPage::Result.new(final_url: "https://jobs.example/rails", title: "Rails", text: "Acme is hiring")
  end

  before do
    allow(CompanyPage).to receive(:collect).and_return([ page ])
    allow(Settings).to receive(:chat_gpt_api_key).and_return("test-key")
  end

  def stub_model(payload)
    chat = instance_double(ChatGpt, call: payload.to_json)
    allow(ChatGpt).to receive(:new).and_return(chat)
  end

  it "links an existing company and keeps the offer sections" do
    existing = create(:company, official_name: "YND Sp. z o.o.", country: "PL",
                      identifiers_attributes: [ { kind: "nip", value: "5252344078" } ])
    stub_model(
      position: "Rails Developer",
      work_mode: "remote",
      sections: [ { key: "requirements", body: "3 years of Rails" } ],
      company: {
        official_name: "YND Sp. z o.o.",
        kind: "employer",
        country: "PL",
        identifiers: [ { kind: "nip", value: "5252344078" } ]
      }
    )
    expect(CompanyFromOffer).not_to receive(:new)

    described_class.new(lookup).call

    expect(lookup.reload.status).to eq("ready")
    expect(lookup.company).to eq(existing)
    application = lookup.to_application
    expect(application.position).to eq("Rails Developer")
    expect(application.company_id).to eq(existing.id)
    expect(application.sections).to eq([ { "key" => "requirements", "body" => "3 years of Rails" } ])
  end

  it "asks the company lookup to create a company that is not in the catalog" do
    stub_model(
      position: "Project Manager",
      sections: [ { key: "description", body: "Lead ERP projects" } ],
      company: { official_name: "Dev4You", kind: "employer", country: "PL", identifiers: [] }
    )
    company_lookup = instance_double(CompanyLookup, company_id: nil, company: nil)
    allow(company_lookup).to receive(:reload).and_return(company_lookup)
    expect(CompanyLookup).to receive(:create!).and_return(company_lookup)
    offer = instance_double(CompanyFromOffer, call: nil)
    expect(CompanyFromOffer).to receive(:new).with(company_lookup).and_return(offer)

    described_class.new(lookup).call

    expect(lookup.reload.status).to eq("ready")
    expect(lookup.payload["position"]).to eq("Project Manager")
    expect(lookup.payload["company_id"]).to be_nil
  end
end
