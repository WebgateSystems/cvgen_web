# frozen_string_literal: true

class GoogleFontsCatalog
  PATH = Rails.root.join("config/data/google_fonts.json")
  SYSTEM = [
    { "id" => nil, "family" => "Helvetica Neue", "category" => "system" },
    { "id" => nil, "family" => "Libertinus Serif", "category" => "system" }
  ].freeze

  def self.families
    SYSTEM + google_families
  end

  def self.google_families
    @google_families ||= JSON.parse(PATH.read)
  end

  def self.ids_by_family
    @ids_by_family ||= google_families.to_h { |font| [ font["family"].downcase, font["id"] ] }
  end

  def self.google_id(family)
    ids_by_family[family.to_s.strip.downcase]
  end

  def self.options_json
    @options_json ||= families.map { |font| { "family" => font["family"], "category" => font["category"] } }.to_json
  end
end
