# frozen_string_literal: true

class CompanyLookup < ApplicationRecord
  STATUSES = %w[queued running found created incomplete failed].freeze
  STEPS = %w[fetching reading matching].freeze
  ATTRIBUTE_KEYS = %w[
    shortcut official_name kind country street city postal_code
  ].freeze

  belongs_to :user
  belongs_to :company, optional: true

  # i18n-tasks-use t('activerecord.errors.models.company_lookup.attributes.source_url.blank')
  validates :source_url, presence: true, length: { maximum: 2000 }
  validates :status, inclusion: { in: STATUSES }
  validate :http_source_url

  def pending?
    status.in?(%w[queued running])
  end

  def company_attributes
    data = payload.is_a?(Hash) ? payload : {}
    data.slice(*ATTRIBUTE_KEYS).compact_blank
  end

  def identifier_attributes
    data = payload.is_a?(Hash) ? payload : {}
    Array(data["identifiers"]).filter_map do |item|
      item = item.to_h.stringify_keys
      next unless CompanyIdentifier::KINDS.include?(item["kind"].to_s)
      next if item["value"].blank?

      item.slice("kind", "value")
    end
  end

  def notes
    payload.is_a?(Hash) ? payload["notes"].presence : nil
  end

  private

  def http_source_url
    return if source_url.blank?

    uri = URI.parse(source_url)
    return if uri.is_a?(URI::HTTP) && uri.host.present?

    # i18n-tasks-use t('activerecord.errors.models.company_lookup.attributes.source_url.invalid')
    errors.add(:source_url, :invalid)
  rescue URI::InvalidURIError
    errors.add(:source_url, :invalid)
  end
end
