# frozen_string_literal: true

require "rails_helper"
require "zip"

RSpec.describe CvDocument do
  def wrap(name, content)
    io = StringIO.new(content)
    io.define_singleton_method(:original_filename) { name }
    io.define_singleton_method(:size) { content.bytesize }
    io
  end

  def docx_bytes(text)
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:body><w:p><w:r><w:t>#{text}</w:t></w:r></w:p></w:body>
      </w:document>
    XML
    Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry("word/document.xml")
      zip.write(xml)
    end.string
  end

  it "reads plain text uploads" do
    document = described_class.new(wrap("cv.txt", "Ada Lovelace\nRuby developer"))
    expect(document.extracted_text).to include("Ada Lovelace")
    expect(document.attach_to_model?).to be(false)
  end

  it "pulls text out of a docx" do
    document = described_class.new(wrap("cv.docx", docx_bytes("Senior Rails Engineer")))
    expect(document.extracted_text).to include("Senior Rails Engineer")
  end

  it "extracts text from a PDF instead of attaching it" do
    page = instance_double(PDF::Reader::Page, text: "Ada Lovelace\nRuby developer")
    allow(PDF::Reader).to receive(:new).and_return(instance_double(PDF::Reader, pages: [ page ]))

    document = described_class.new(wrap("cv.pdf", "%PDF-1.4"))
    expect(document.extracted_text).to include("Ada Lovelace")
    expect(document.attach_to_model?).to be(false)
    expect(document.pdf?).to be(true)
  end

  it "returns no text for a malformed PDF" do
    document = described_class.new(wrap("cv.pdf", "%PDF-1.4"))
    expect(document.extracted_text).to eq("")
  end

  it "attaches images for the model instead of extracting" do
    image = described_class.new(wrap("cv.png", "\x89PNG\r\n\x1A\n"))
    expect(image.extracted_text).to eq("")
    expect(image.attach_to_model?).to be(true)
  end

  it "rejects unsupported extensions" do
    expect { described_class.new(wrap("notes.exe", "MZ")) }.to raise_error(CvAnalysis::UnsupportedFile)
  end
end
