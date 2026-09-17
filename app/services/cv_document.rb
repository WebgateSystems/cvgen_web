# frozen_string_literal: true

require "pdf-reader"
require "zip"

class CvDocument
  MAX_BYTES = 8.megabytes
  TEXT_EXT = %w[txt md html htm csv].freeze
  IMAGE_EXT = %w[png jpg jpeg webp gif].freeze
  PDF_EXT = %w[pdf].freeze
  DOCX_EXT = %w[docx].freeze
  DOC_EXT = %w[doc].freeze
  ODT_EXT = %w[odt].freeze
  RTF_EXT = %w[rtf].freeze
  ALLOWED_EXT = (TEXT_EXT + IMAGE_EXT + PDF_EXT + DOCX_EXT + DOC_EXT + ODT_EXT + RTF_EXT).freeze

  WORD_NS = { "w" => "http://schemas.openxmlformats.org/wordprocessingml/2006/main" }.freeze

  attr_reader :filename, :ext, :upload

  def initialize(upload)
    @upload = upload
    @filename = upload.try(:original_filename).presence || upload.try(:path) && File.basename(upload.path) || "upload"
    @ext = File.extname(@filename).delete(".").downcase
    validate!
  end

  def image?
    IMAGE_EXT.include?(ext)
  end

  def pdf?
    PDF_EXT.include?(ext)
  end

  def attach_to_model?
    image?
  end

  def extracted_text
    @extracted_text ||= extract.to_s.strip
  end

  def io_for_model
    rewind
    upload
  end

  private

  def validate!
    raise CvAnalysis::UnsupportedFile.new(filename) unless ALLOWED_EXT.include?(ext)
    raise CvAnalysis::TooLarge.new(filename) if file_size > MAX_BYTES
  end

  def file_size
    if upload.respond_to?(:size)
      upload.size.to_i
    else
      binary.bytesize
    end
  end

  def extract
    case ext
    when *TEXT_EXT then extract_plain
    when *RTF_EXT then extract_rtf
    when *DOCX_EXT then extract_docx
    when *ODT_EXT then extract_odt
    when *DOC_EXT then extract_doc
    when *PDF_EXT then extract_pdf
    when *IMAGE_EXT then ""
    else ""
    end
  end

  def extract_plain
    raw = binary
    raw = Nokogiri::HTML(raw).text if %w[html htm].include?(ext)
    raw.to_s.force_encoding("UTF-8").scrub
  end

  def extract_rtf
    extract_plain
      .gsub(/\\'[0-9a-f]{2}/i) { |token| hex_char(token[-2, 2]) }
      .gsub(/\\[a-z]+\-?\d* ?/i, " ")
      .gsub(/[{}]/, " ")
      .gsub(/\s+/, " ")
  end

  def extract_docx
    xml = zip_entry("word/document.xml")
    return "" if xml.blank?

    Nokogiri::XML(xml).xpath("//w:t", WORD_NS).map(&:text).join(" ")
  end

  def extract_odt
    xml = zip_entry("content.xml")
    return "" if xml.blank?

    doc = Nokogiri::XML(xml)
    doc.remove_namespaces!
    doc.xpath("//p | //h | //span").map(&:text).join(" ")
  end

  def extract_pdf
    source = reader_source
    source.rewind if source.respond_to?(:rewind)
    PDF::Reader.new(source).pages.map { |page| page.text.to_s }.join("\n")
  rescue StandardError
    ""
  ensure
    rewind
  end

  def reader_source
    if upload.respond_to?(:tempfile)
      upload.tempfile
    elsif upload.respond_to?(:path) && upload.path.present? && !upload.is_a?(StringIO)
      upload.path
    else
      StringIO.new(binary.b)
    end
  end

  def extract_doc
    data = binary.b
    utf16 = data.scan(/(?:[\x20-\x7E]\x00){6,}/n).map { |chunk| chunk.delete("\x00") }
    ascii = data.scan(/[\x20-\x7E]{6,}/n)
    [ utf16, ascii ].flatten.join("\n").squeeze(" ")
  end

  def zip_entry(name)
    Zip::InputStream.open(StringIO.new(binary.b)) do |zip|
      while (entry = zip.get_next_entry)
        return zip.read if entry.name == name
      end
    end
    ""
  end

  def hex_char(hex)
    code = hex.to_i(16)
    code.between?(32, 126) ? code.chr : " "
  end

  def binary
    rewind
    upload.read.to_s
  ensure
    rewind
  end

  def rewind
    upload.rewind if upload.respond_to?(:rewind)
  end
end
