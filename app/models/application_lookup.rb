# frozen_string_literal: true

class ApplicationLookup < ApplicationRecord
  STATUSES = %w[queued running ready failed].freeze
  STEPS = %w[fetching reading company].freeze
  PROGRESS_STEPS = %w[queued fetching reading company ready].freeze
  APPLICATION_KEYS = %w[
    position posted_on expected_salary offered_salary work_mode
    employment_type contract_type link email
  ].freeze

  belongs_to :user
  belongs_to :company, optional: true

  # i18n-tasks-use t('activerecord.errors.models.application_lookup.attributes.source_url.blank')
  validates :source_url, presence: true, length: { maximum: 2000 }
  validates :status, inclusion: { in: STATUSES }
  validate :http_source_url

  def pending?
    status.in?(%w[queued running])
  end

  def progress_index
    key = if status == "queued"
      "queued"
    elsif status == "ready"
      "ready"
    else
      step.presence || "fetching"
    end
    PROGRESS_STEPS.index(key) || 0
  end

  def step_state(key)
    index = PROGRESS_STEPS.index(key)
    current = progress_index
    if status == "failed"
      return "failed" if index == current
      return "done" if index < current

      return "upcoming"
    end
    return "done" if status == "ready" || index < current
    return "current" if index == current

    "upcoming"
  end

  def to_application
    data = payload.is_a?(Hash) ? payload : {}
    application = user.job_applications.new(application_attributes(data))
    application.sections = data["sections"]
    application.link = data["link"].presence || source_url
    attach_company(application, data)
    application
  end

  private

  def application_attributes(data)
    attrs = data.slice(*APPLICATION_KEYS)
    attrs["posted_on"] = parse_date(attrs["posted_on"])
    attrs["work_mode"] = nil unless JobApplication::WORK_MODES.include?(attrs["work_mode"].to_s)
    attrs["employment_type"] = nil unless JobApplication::EMPLOYMENT_TYPES.include?(attrs["employment_type"].to_s)
    attrs["contract_type"] = nil unless JobApplication::CONTRACT_TYPES.include?(attrs["contract_type"].to_s)
    attrs["status"] = "reviewed"
    attrs.compact_blank
  end

  def attach_company(application, data)
    if data["company_id"].present?
      company = Company.includes(:identifiers).find_by(id: data["company_id"])
      if company
        application.company = company
        return
      end
    end

    company_data = data["company"].is_a?(Hash) ? data["company"] : {}
    attributes = company_data.slice(*CompanyLookup::ATTRIBUTE_KEYS).compact_blank
    attributes["kind"] = company_data["kind"].presence || "employer"
    application.build_company(attributes)
    Array(company_data["identifiers"]).each do |item|
      item = item.to_h.stringify_keys
      next unless CompanyIdentifier::KINDS.include?(item["kind"].to_s)

      application.company.identifiers.build(kind: item["kind"], value: item["value"])
    end
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error, ArgumentError
    nil
  end

  def http_source_url
    return if source_url.blank?

    uri = URI.parse(source_url)
    return if uri.is_a?(URI::HTTP) && uri.host.present?

    # i18n-tasks-use t('activerecord.errors.models.application_lookup.attributes.source_url.invalid')
    errors.add(:source_url, :invalid)
  rescue URI::InvalidURIError
    errors.add(:source_url, :invalid)
  end
end
