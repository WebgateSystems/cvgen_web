# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyFromOffer do
  let(:lookup) do
    CompanyLookup.create!(
      user: create(:user, :admin),
      source_url: "https://jobs.example/rails",
      status: "queued"
    )
  end
  let(:page) do
    CompanyPage::Result.new(final_url: "https://jobs.example/rails", title: "Rails", text: "Acme is hiring")
  end

  before do
    allow(CompanyPage).to receive(:collect).and_return([ page ])
    allow(CompanyRegistry).to receive(:pages_for).and_return([])
    allow(Settings).to receive(:chat_gpt_api_key).and_return("test-key")
  end

  def stub_model(payload)
    chat = instance_double(ChatGpt, call: payload.to_json)
    allow(ChatGpt).to receive(:new) do |**kwargs|
      @chat_gpt_kwargs = kwargs
      chat
    end
  end

  it "records an existing company instead of creating a duplicate" do
    existing = create(:company, official_name: "YND Sp. z o.o.", country: "PL",
                      identifiers_attributes: [ { kind: "nip", value: "5252344078" } ])
    stub_model(
      official_name: "YND Sp. z o.o.",
      kind: "employer",
      country: "PL",
      identifiers: [
        { kind: "nip", value: "5252344078" },
        { kind: "krs", value: "0000999888" }
      ],
      notes: "NIP and KRS from the public register."
    )

    expect { described_class.new(lookup).call }.not_to change(Company, :count)
    expect(lookup.reload.status).to eq("found")
    expect(lookup.company).to eq(existing)
    expect(lookup.notes).to eq("NIP and KRS from the public register.")
    expect(@chat_gpt_kwargs).to include(web_search: true)
  end

  it "creates a company with every identifier the lookup returned" do
    stub_model(
      official_name: "Northwind Recruiting Ltd",
      shortcut: "Northwind",
      kind: "agency",
      country: "GB",
      city: "London",
      identifiers: [ { kind: "company_number", value: "12345678" } ],
      notes: "Companies House."
    )

    expect { described_class.new(lookup).call }.to change(Company, :count).by(1)
    expect(lookup.reload.status).to eq("created")
    expect(lookup.company.kind).to eq("agency")
    expect(lookup.company.identifiers.map { |identifier| [ identifier.kind, identifier.value ] }).to eq([ %w[company_number 12345678] ])
  end

  it "leaves an incomplete draft when no identifier was found" do
    stub_model(official_name: "Mystery Co", kind: "employer", country: "PL", identifiers: [], notes: "No register entry.")

    expect { described_class.new(lookup).call }.not_to change(Company, :count)
    expect(lookup.reload.status).to eq("incomplete")
    expect(lookup.company_attributes["official_name"]).to eq("Mystery Co")
  end

  it "sends the company site opened from the offer and still answers when web search fails" do
    careers = CompanyPage::Result.new(
      final_url: "https://red-sky.com/careers/",
      title: "Careers",
      text: "NIP 642-26-83-651 KRS 0000209107 Szczecin"
    )
    allow(CompanyPage).to receive(:collect).and_return([ page, careers ])
    calls = []
    allow(ChatGpt).to receive(:new) do |**kwargs|
      calls << kwargs
      raise "tool rejected" if kwargs[:web_search]

      instance_double(ChatGpt, call: {
        official_name: "Red Sky Sp. z o.o.",
        kind: "employer",
        country: "PL",
        city: "Szczecin",
        identifiers: [
          { kind: "nip", value: "6422683651" },
          { kind: "krs", value: "0000209107" }
        ]
      }.to_json)
    end

    expect { described_class.new(lookup).call }.to change(Company, :count).by(1)
    expect(calls.map { |kwargs| kwargs[:web_search] }).to eq([ true, false ])
    expect(calls.first[:prompt]).to include("https://red-sky.com/careers/")
    expect(calls.first[:prompt]).to include("642-26-83-651")
    expect(lookup.reload.company.identifiers.map(&:value)).to contain_exactly("6422683651", "0000209107")
  end

  it "fills NIP and REGON from a public register when the model leaves identifiers empty" do
    registry = CompanyPage::Result.new(
      final_url: "https://www.krs-online.com.pl/firma/7080551-pawel-sydorow-devforyou",
      title: "Paweł Sydorów Devforyou",
      text: "Paweł Sydorów Devforyou NIP: 7811963049 REGON: 369271291 Inna firma NIP: 5252344078"
    )
    allow(CompanyRegistry).to receive(:pages_for).and_return([ registry ])
    stub_model(official_name: "Dev4You", kind: "employer", country: "PL", city: "Poznań", identifiers: [])

    expect { described_class.new(lookup).call }.to change(Company, :count).by(1)
    expect(CompanyRegistry).to have_received(:pages_for).with(name: "Dev4You", city: "Poznań", country: "PL")
    expect(@chat_gpt_kwargs[:prompt]).to include("krs-online.com.pl")
    expect(lookup.reload.company.identifiers.map { |identifier| [ identifier.kind, identifier.value ] })
      .to contain_exactly(%w[nip 7811963049], %w[regon 369271291])
  end

  it "keeps the register identifiers when the follow-up model call fails" do
    registry = CompanyPage::Result.new(
      final_url: "https://www.krs-online.com.pl/firma/7080551-pawel-sydorow-devforyou",
      title: "Paweł Sydorów Devforyou",
      text: "NIP: 7811963049 REGON: 369271291"
    )
    allow(CompanyRegistry).to receive(:pages_for).and_return([ registry ])
    allow(ChatGpt).to receive(:new) do |**kwargs|
      raise "model down" if kwargs[:prompt].include?("7080551-pawel-sydorow-devforyou")

      instance_double(ChatGpt, call: {
        official_name: "Dev4You", kind: "employer", country: "PL", city: "Poznań", identifiers: []
      }.to_json)
    end

    expect { described_class.new(lookup).call }.to change(Company, :count).by(1)
    expect(lookup.reload.status).to eq("created")
    expect(lookup.company.identifiers.map(&:value)).to contain_exactly("7811963049", "369271291")
  end
end
