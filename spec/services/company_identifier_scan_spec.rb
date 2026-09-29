# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyIdentifierScan do
  it "reads the first labelled NIP and REGON and ignores a later firm" do
    text = "Paweł Sydorów Devforyou NIP: 7811963049 REGON: 369271291 Inna firma NIP: 5252344078"

    expect(described_class.call([ text ])).to eq([
      { "kind" => "nip", "value" => "7811963049" },
      { "kind" => "regon", "value" => "369271291" }
    ])
  end

  it "reads a KRS printed with the label" do
    expect(described_class.call([ "KRS: 0000209107" ])).to eq([
      { "kind" => "krs", "value" => "0000209107" }
    ])
  end

  it "rejects a NIP that fails the checksum" do
    expect(described_class.call([ "NIP: 1234567890" ])).to eq([])
  end

  it "uses the first page that actually contains an identifier" do
    expect(described_class.call([ "Wpisz NIP", "NIP: 781-196-30-49" ])).to eq([
      { "kind" => "nip", "value" => "7811963049" }
    ])
  end
end
