# frozen_string_literal: true

class CompanyMatch
  def self.call(attrs)
    new(attrs).call
  end

  def initialize(attrs)
    @attrs = attrs.to_h.stringify_keys
  end

  def call
    by_identifier || by_name_and_identifiers
  end

  private

  def pairs
    @pairs ||= Array(@attrs["identifiers"]).filter_map do |item|
      item = item.to_h.stringify_keys
      identifier = CompanyIdentifier.new(kind: item["kind"], value: item["value"])
      identifier.validate
      next if identifier.kind.blank? || identifier.value.blank?

      [ identifier.kind, identifier.value ]
    rescue ArgumentError
      nil
    end.uniq
  end

  def by_identifier
    pairs.each do |kind, value|
      found = CompanyIdentifier.find_by(kind: kind, value: value)
      return found.company if found
    end
    nil
  end

  def by_name_and_identifiers
    name = @attrs["official_name"].to_s.strip
    country = @attrs["country"].to_s.upcase
    return if name.blank? || pairs.empty?

    Company.where("LOWER(official_name) = ?", name.downcase).includes(:identifiers).find do |company|
      company.country.to_s == country && pairs.any? do |kind, value|
        company.identifiers.any? { |identifier| identifier.kind == kind && identifier.value == value }
      end
    end
  end
end
