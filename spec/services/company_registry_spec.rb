# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyRegistry do
  it "unwraps DuckDuckGo results and keeps the register ahead of the company site" do
    links = [
      "https://justjoin.it/job-offer/dev4you",
      "https://www.linkedin.com/company/dev4you",
      "https://duckduckgo.com/l/?uddg=https%3A%2F%2Fdev4you.pl%2F",
      "https://duckduckgo.com/l/?uddg=https%3A%2F%2Fwww.krs-online.com.pl%2Ffirma%2F7080551-pawel-sydorow-devforyou",
      "https://dev4you.pl/logo.png"
    ]

    expect(described_class.targets_from(links)).to eq([
      "https://www.krs-online.com.pl/firma/7080551-pawel-sydorow-devforyou",
      "https://dev4you.pl/"
    ])
  end

  it "fetches the register pages named in the search results" do
    register = CompanyPage::Result.new(
      final_url: "https://www.krs-online.com.pl/firma/7080551",
      title: "Dev4You",
      text: "NIP: 7811963049"
    )
    reader = instance_double(
      CompanyPage,
      read: [
        CompanyPage::Result.new(final_url: "https://html.duckduckgo.com/html/", title: "search", text: ""),
        [ "https://duckduckgo.com/l/?uddg=https%3A%2F%2Fwww.krs-online.com.pl%2Ffirma%2F7080551" ]
      ]
    )
    allow(CompanyPage).to receive(:new).and_return(reader)
    allow(CompanyPage).to receive(:fetch).with("https://www.krs-online.com.pl/firma/7080551").and_return(register)

    expect(described_class.pages_for(name: "Dev4You", city: "Poznań", country: "PL")).to eq([ register ])
  end

  it "returns no pages when the search itself cannot be fetched" do
    reader = instance_double(CompanyPage)
    allow(reader).to receive(:read).and_raise(CompanyPage::FetchFailed)
    allow(CompanyPage).to receive(:new).and_return(reader)

    expect(described_class.pages_for(name: "Dev4You", country: "DE")).to eq([])
  end

  it "skips a register page that cannot be fetched" do
    reader = instance_double(
      CompanyPage,
      read: [
        CompanyPage::Result.new(final_url: "https://html.duckduckgo.com/html/", title: "search", text: ""),
        [ "https://www.krs-online.com.pl/firma/7080551" ]
      ]
    )
    allow(CompanyPage).to receive(:new).and_return(reader)
    allow(CompanyPage).to receive(:fetch).and_raise(CompanyPage::FetchFailed)

    expect(described_class.pages_for(name: "Dev4You")).to eq([])
  end
end
