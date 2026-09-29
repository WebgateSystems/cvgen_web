# frozen_string_literal: true

class CompanyIdentifier < ApplicationRecord
  KINDS = %w[nip krs regon vat vat_eu ein company_number other].freeze

  belongs_to :company, inverse_of: :identifiers

  enum :kind, KINDS.index_with(&:itself), validate: true

  before_validation :normalize_value

  validates :value, presence: true, length: { maximum: 40 }
  validates :value, uniqueness: { scope: :kind, case_sensitive: false }

  def self.normalize(kind, value)
    raw = value.to_s.gsub(/[\s-]+/, "")
    return if raw.blank?

    kind.to_s == "vat_eu" ? raw.upcase : raw
  end

  private

  def normalize_value
    self.value = self.class.normalize(kind, value)
  end
end
