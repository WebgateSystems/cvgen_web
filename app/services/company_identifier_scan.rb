# frozen_string_literal: true

class CompanyIdentifierScan
  NIP_WEIGHTS = [ 6, 5, 7, 2, 3, 4, 5, 6, 7 ].freeze
  REGON9_WEIGHTS = [ 8, 9, 2, 3, 4, 5, 6, 7 ].freeze
  REGON14_WEIGHTS = [ 2, 4, 8, 5, 0, 9, 7, 3, 6, 1, 2, 4, 8 ].freeze

  PATTERNS = {
    "nip" => /NIP(?!\s*UE)\s*[:\-]?\s*(\d(?:[\d \-]){8,14}\d)/i,
    "regon" => /REGON\s*[:\-]?\s*(\d(?:[\d \-]){7,16}\d)/i,
    "krs" => /KRS\s*[:\-]?\s*(\d(?:[\d \-]){8,14}\d)/i
  }.freeze

  def self.call(texts)
    Array(texts).each do |text|
      found = new(text.to_s).call
      return found if found.any?
    end
    []
  end

  def initialize(text)
    @text = text
  end

  def call
    PATTERNS.filter_map do |kind, pattern|
      match = @text.match(pattern)
      next unless match

      value = CompanyIdentifier.normalize(kind, match[1])
      next unless valid?(kind, value)

      { "kind" => kind, "value" => value }
    end
  end

  private

  def valid?(kind, value)
    case kind
    when "nip" then value.match?(/\A\d{10}\z/) && checksum?(value, NIP_WEIGHTS)
    when "regon" then regon?(value)
    when "krs" then value.match?(/\A\d{10}\z/)
    else false
    end
  end

  def regon?(value)
    case value.length
    when 9 then checksum?(value, REGON9_WEIGHTS)
    when 14 then checksum?(value, REGON14_WEIGHTS)
    else false
    end
  end

  def checksum?(digits, weights)
    numbers = digits.chars.map(&:to_i)
    check = numbers.pop
    sum = weights.each_with_index.sum { |weight, index| weight * numbers[index] }
    expected = sum % 11
    expected != 10 && expected == check
  end
end
