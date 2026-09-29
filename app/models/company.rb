# frozen_string_literal: true

class Company < ApplicationRecord
  KINDS = %w[employer agency].freeze
  COUNTRIES = %w[
    PL DE GB US NL CZ SK FR ES IT AT BE SE NO DK FI IE LT LV EE UA
  ].freeze

  has_many :job_applications, dependent: :restrict_with_error, inverse_of: :company
  has_many :company_ratings, dependent: :destroy
  has_many :identifiers, class_name: "CompanyIdentifier", dependent: :destroy, inverse_of: :company

  accepts_nested_attributes_for :identifiers, allow_destroy: true, reject_if: :blank_identifier?

  enum :kind, KINDS.index_with(&:itself), default: :employer, validate: true

  before_validation :normalize_fields

  validates :official_name, presence: true, length: { maximum: 160 }
  validates :shortcut, length: { maximum: 40 }, allow_blank: true
  validates :kind, inclusion: { in: KINDS }
  validates :country, inclusion: { in: COUNTRIES }, allow_blank: true
  # i18n-tasks-use t('activerecord.errors.models.company.attributes.country.blank')
  validates :country, presence: true, unless: :legacy_without_country?
  validates :street, :city, :postal_code, length: { maximum: 160 }, allow_blank: true
  validate :at_least_one_identifier

  scope :search_text, ->(query) {
    q = query.to_s.strip
    if q.length < 2
      all
    else
      pattern = "%#{sanitize_sql_like(q)}%"
      left_joins(:identifiers).where(
        "companies.shortcut ILIKE :q OR companies.official_name ILIKE :q OR company_identifiers.value ILIKE :q",
        q: pattern
      ).distinct
    end
  }

  def display_name
    shortcut.presence || official_name
  end

  def label
    parts = [ display_name ]
    parts << official_name if shortcut.present? && official_name.present? && shortcut != official_name
    parts << country if country.present?
    parts.compact.join(" · ")
  end

  def overall_rating
    ratings = loaded_ratings
    return if ratings.empty?

    mean = ratings.sum { |rating| rating.overall.to_d } / ratings.size
    mean.round(1)
  end

  def dimension_averages
    ratings = loaded_ratings
    CompanyRating::DIMENSIONS.index_with do |dimension|
      next if ratings.empty?

      mean = ratings.sum { |rating| rating.public_send(dimension).to_d } / ratings.size
      mean.round(1)
    end
  end

  def formatted_rating
    value = overall_rating
    value ? format("%.1f", value) : nil
  end

  private

  def loaded_ratings
    company_ratings.loaded? ? company_ratings.target : company_ratings.to_a
  end

  def legacy_without_country?
    persisted? && attribute_in_database("country").blank?
  end

  def blank_identifier?(attrs)
    return false if ActiveModel::Type::Boolean.new.cast(attrs["_destroy"] || attrs[:_destroy])

    (attrs["value"] || attrs[:value]).blank?
  end

  def at_least_one_identifier
    kept = identifiers.reject(&:marked_for_destruction?).select { |identifier| identifier.value.present? }
    # i18n-tasks-use t('activerecord.errors.models.company.attributes.identifiers.blank')
    errors.add(:identifiers, :blank) if kept.empty?
  end

  def normalize_fields
    self.shortcut = shortcut.to_s.strip.presence
    self.official_name = official_name.to_s.strip.presence
    self.country = country.to_s.upcase.presence
    %i[street city postal_code].each do |field|
      public_send("#{field}=", public_send(field).to_s.strip.presence)
    end
  end
end
