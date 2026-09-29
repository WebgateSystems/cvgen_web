# frozen_string_literal: true

require "rails_helper"

RSpec.describe TypstFontName do
  def ttf_with_family(family)
    utf16 = family.encode("UTF-16BE").b
    rec = [ 3, 1, 0x409, 1, utf16.bytesize, 0 ].pack("n6")
    table = [ 0, 1, 18 ].pack("n3") + rec + utf16
    checksum = 0
    padded = table + ("\x00".b * ((4 - (table.bytesize % 4)) % 4))
    padded.unpack("N*").each { |word| checksum = (checksum + word) & 0xFFFFFFFF }
    header = [ 0x00010000, 1, 16, 0, 0 ].pack("Nn4")
    record = [ "name", checksum, header.bytesize + 16, table.bytesize ].pack("a4N3")
    header + record + table
  end

  def family_from(path)
    data = Pathname(path).binread
    num = data.unpack1("@4n")
    num.times do |i|
      rec = 12 + (i * 16)
      next unless data.byteslice(rec, 4) == "name"

      offset = data.unpack1("@#{rec + 8}N")
      table = data.byteslice(offset, data.unpack1("@#{rec + 12}N"))
      count = table.unpack1("@2n")
      storage = table.unpack1("@4n")
      count.times do |j|
        plat, _enc, _lang, nid, len, roff = table.unpack("@#{6 + (j * 12)}n6")
        next unless plat == 3 && nid == 1

        return table.byteslice(storage + roff, len).to_s.force_encoding("UTF-16BE").encode("UTF-8")
      end
    end
    nil
  end

  it "keeps system families unchanged and marks Google Fonts for Typst" do
    expect(described_class.typst_family("Helvetica Neue")).to eq("Helvetica Neue")
    expect(described_class.typst_family("Roboto Condensed")).to eq("Roboto Condensed\u{200B}")
  end

  it "rewrites the OpenType family name in a TTF" do
    Dir.mktmpdir do |dir|
      path = Pathname(dir).join("font.ttf")
      path.binwrite(ttf_with_family("Roboto Condensed"))
      described_class.set!(path, described_class.typst_family("Roboto Condensed"))
      expect(family_from(path)).to eq("Roboto Condensed\u{200B}")
    end
  end
end
