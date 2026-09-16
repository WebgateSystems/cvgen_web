# frozen_string_literal: true

class Company < ApplicationRecord
  KINDS = %w[employer agency].freeze
  LEGAL_ID_KINDS = %w[nip krs vat ein company_number other].freeze
  COUNTRIES = %w[
    PL DE GB US NL CZ SK FR ES IT AT BE SE NO DK FI IE LT LV EE UA
  ].freeze

  has_many :job_applications, dependent: :restrict_with_error, inverse_of: :company
  has_many :company_ratings, dependent: :destroy

  enum :kind, KINDS.index_with(&:itself), default: :employer, validate: true
  enum :legal_id_kind, LEGAL_ID_KINDS.index_with(&:itself), validate: { allow_nil: true }

  before_validation :normalize_fields

  validates :official_name, presence: true, length: { maximum: 160 }
  validates :shortcut, length: { maximum: 40 }, allow_blank: true
  validates :kind, inclusion: { in: KINDS }
  validates :country, inclusion: { in: COUNTRIES }, allow_blank: true
  validates :legal_id, :legal_id_kind, :country, presence: true, unless: :legacy_record?
  validates :legal_id, length: { maximum: 40 }, allow_blank: true
  validates :street, :city, :postal_code, length: { maximum: 160 }, allow_blank: true
  validates :legal_id, uniqueness: { scope: %i[country legal_id_kind], case_sensitive: false },
            allow_blank: true

  scope :search_text, ->(query) {
    q = query.to_s.strip
    if q.length < 2
      all
    else
      pattern = "%#{sanitize_sql_like(q)}%"
      where("shortcut ILIKE :q OR official_name ILIKE :q OR legal_id ILIKE :q", q: pattern)
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

  def legacy_record?
    persisted? && legal_id.blank?
  end

  def normalize_fields
    self.shortcut = shortcut.to_s.strip.presence
    self.official_name = official_name.to_s.strip.presence
    self.legal_id = legal_id.to_s.gsub(/[\s-]+/, "").presence
    self.country = country.to_s.upcase.presence
    self.legal_id_kind = nil if self[:legal_id_kind].blank?
    %i[street city postal_code].each do |field|
      public_send("#{field}=", public_send(field).to_s.strip.presence)
    end
  end
end
