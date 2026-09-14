# frozen_string_literal: true

class JobApplication < ApplicationRecord
  STATUSES = %w[reviewed applied interview offer rejected withdrawn].freeze
  WORK_MODES = %w[remote hybrid onsite].freeze
  EMPLOYMENT_TYPES = %w[full_time part_time contract].freeze
  CONTRACT_TYPES = %w[b2b employment mandate specific_task].freeze

  belongs_to :user

  enum :status, STATUSES.index_with(&:itself), default: :reviewed, validate: true
  enum :work_mode, WORK_MODES.index_with(&:itself), validate: { allow_nil: true }
  enum :employment_type, EMPLOYMENT_TYPES.index_with(&:itself), validate: { allow_nil: true }
  enum :contract_type, CONTRACT_TYPES.index_with(&:itself), validate: { allow_nil: true }

  before_validation :normalize_optional_fields

  validates :position, :company, presence: true
  validates :position, :company, length: { maximum: 160 }
  validates :expected_salary, :offered_salary, length: { maximum: 80 }, allow_blank: true
  validates :link, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  INDEX_COLUMNS = %w[
    position company posted_on status
    expected_salary offered_salary work_mode employment_type contract_type
    link email
  ].freeze
  INDEX_DEFAULT_COLUMNS = %w[position company posted_on status].freeze
  PAGE_SIZE = 30

  scope :recent, -> { order(updated_at: :desc, id: :desc) }
  scope :search_text, ->(query) {
    q = query.to_s.strip
    if q.length < 3
      all
    else
      pattern = "%#{JobApplication.sanitize_sql_like(q)}%"
      where("position ILIKE :q OR company ILIKE :q", q: pattern)
    end
  }

  def self.status_options
    statuses.keys
  end

  private

  def normalize_optional_fields
    %i[expected_salary offered_salary work_mode employment_type contract_type link email].each do |field|
      value = public_send(field)
      public_send("#{field}=", value.presence)
    end
  end
end
