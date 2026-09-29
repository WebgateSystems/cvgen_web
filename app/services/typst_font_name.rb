# frozen_string_literal: true

# Typst 0.13+ strips width suffixes such as "Condensed" from OpenType family
# names. Google Fonts are rewritten so the TTF name matches the theme YAML.
class TypstFontName
  MARKER = "\u{200B}"
  FAMILY_IDS = [ 1, 16 ].freeze

  def self.typst_family(family)
    if defined?(Cvgen::TtfFamilyName)
      return Cvgen::TtfFamilyName.typst_family(family)
    end

    key = family.to_s.strip
    return key if key.empty? || key.end_with?(MARKER)
    return key if system?(key)

    "#{key}#{MARKER}"
  end

  def self.system?(family)
    key = family.to_s.strip.downcase
    return true if key.empty?
    return true if defined?(Cvgen::FontResolver) && Cvgen::FontResolver::BUILTIN_FONTS.include?(key)

    GoogleFontsCatalog.google_id(family).blank?
  end

  def self.patch_workspace!(root, theme_data)
    fonts = (theme_data || {})["fonts"] || {}
    [ fonts["heading"], fonts["body"] ].map { |value| value.to_s.strip }.reject(&:empty?).uniq.each do |family|
      next if system?(family)

      id = GoogleFontsCatalog.google_id(family)
      next if id.blank?

      dir = Pathname(root).join("fonts", id)
      next unless dir.directory?

      Dir[dir.join("*.ttf").to_s].each { |path| set!(path, typst_family(family)) }
    end
  end

  def self.set!(path, family)
    if defined?(Cvgen::TtfFamilyName)
      Cvgen::TtfFamilyName.set!(path, family)
    else
      new(path).set!(family)
    end
  end

  def initialize(path)
    @path = Pathname(path)
  end

  def set!(family)
    data = @path.binread.b
    return if data.bytesize < 28

    num = u16(data, 4)
    return if num.zero? || num > 64
    return if data.bytesize < (12 + (num * 16))

    name_rec = nil
    num.times do |i|
      rec = 12 + (i * 16)
      next unless data.byteslice(rec, 4) == "name"

      name_rec = rec
      break
    end
    return if name_rec.nil?

    offset = u32(data, name_rec + 8)
    length = u32(data, name_rec + 12)
    table = data.byteslice(offset, length)
    return if table.nil? || table.bytesize < 6

    count = u16(table, 2)
    storage = u16(table, 4)
    records = count.times.map do |i|
      rec = 6 + (i * 12)
      plat, enc, lang, nid, len, roff = table.unpack("@#{rec}n6")
      raw = table.byteslice(storage + roff, len).to_s
      [ plat, enc, lang, nid, raw ]
    end

    utf16 = family.encode("UTF-16BE").b
    rewritten = []
    seen_16 = false
    records.each do |plat, enc, lang, nid, raw|
      if FAMILY_IDS.include?(nid)
        next if plat != 3

        rewritten << [ plat, enc, lang, nid, utf16 ]
        seen_16 = true if nid == 16
      else
        rewritten << [ plat, enc, lang, nid, raw.to_s.b ]
      end
    end
    rewritten << [ 3, 1, 0x409, 16, utf16 ] unless seen_16

    storage_blob = "".b
    recs = "".b
    rewritten.each do |plat, enc, lang, nid, raw|
      recs << [ plat, enc, lang, nid, raw.bytesize, storage_blob.bytesize ].pack("n6")
      storage_blob << raw.b
    end
    new_table = [ 0, rewritten.length, 6 + (12 * rewritten.length) ].pack("n3") + recs + storage_blob
    pad = (4 - (new_table.bytesize % 4)) % 4
    padded = new_table + ("\x00".b * pad)

    new_offset = (data.bytesize + 3) & ~3
    out = data.dup
    out << ("\x00".b * (new_offset - data.bytesize)) if data.bytesize < new_offset
    out << padded
    checksum = table_checksum(padded)
    packed = [ checksum, new_offset, new_table.bytesize ].pack("N3")
    out[name_rec + 4, 12] = packed
    @path.binwrite(out)
  end

  private

  def u16(data, offset)
    data.unpack1("@#{offset}n")
  end

  def u32(data, offset)
    data.unpack1("@#{offset}N")
  end

    def table_checksum(bytes)
      bytes = bytes.b
      padded = bytes + ("\x00".b * ((4 - (bytes.bytesize % 4)) % 4))
    sum = 0
    padded.unpack("N*").each { |word| sum = (sum + word) & 0xFFFFFFFF }
    sum
  end
end
