# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyPage do
  it "rejects a non-http address" do
    expect { described_class.fetch("file:///etc/passwd") }.to raise_error(described_class::InvalidUrl)
  end

  it "rejects a host that resolves to a private address" do
    allow(Resolv).to receive(:getaddresses).with("intranet.example").and_return([ "127.0.0.1" ])

    expect { described_class.fetch("https://intranet.example/jobs") }.to raise_error(described_class::BlockedHost)
  end

  it "follows the company site linked from a job board and skips the board, social links, and assets" do
    links = described_class.followable_links(
      [
        "https://justjoin.it/job-offer/other",
        "https://www.linkedin.com/company/red-sky",
        "https://red-sky.com/logo.png",
        "https://red-sky.com/careers/",
        "https://red-sky.com/careers/#footer"
      ],
      "https://justjoin.it/job-offer/red-sky-coo-cto-co-founder-warszawa-ai"
    )

    expect(links).to eq([ "https://red-sky.com/careers/" ])
  end

  it "prefers a legal or contact page on the same company site" do
    links = described_class.followable_links(
      [ "https://red-sky.com/blog/hello", "https://red-sky.com/legal" ],
      "https://red-sky.com/careers/"
    )

    expect(links.first).to eq("https://red-sky.com/legal")
  end

  it "opens the company site linked from the offer and keeps the footer when the page is long" do
    offer = <<~HTML
      <html><head><title>Offer</title></head>
      <body><a href="https://red-sky.com/careers/">Red Sky</a> #{'word ' * 20_000}</body></html>
    HTML
    careers = <<~HTML
      <html><head><title>Careers</title></head>
      <body>NIP 642-26-83-651 KRS 0000209107</body></html>
    HTML
    allow(Resolv).to receive(:getaddresses).and_return([ "93.184.216.34" ])
    allow(Net::HTTP).to receive(:start) do |host, *_args, **_kwargs, &block|
      body = host == "red-sky.com" ? careers : offer
      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return(body)
      http = instance_double(Net::HTTP, request: response)
      block.call(http)
    end

    pages = described_class.collect("https://jobs.example/offer")

    expect(pages.map(&:final_url)).to eq([ "https://jobs.example/offer", "https://red-sky.com/careers/" ])
    expect(pages.first.text).to include("…")
    expect(pages.last.text).to include("642-26-83-651")
  end
end
