# frozen_string_literal: true

class JobApplication < ApplicationRecord
  STATUSES = %w[reviewed applied interview offer rejected withdrawn].freeze
  WORK_MODES = %w[remote hybrid onsite].freeze
  EMPLOYMENT_TYPES = %w[full_time part_time contract].freeze
  CONTRACT_TYPES = %w[b2b employment mandate specific_task].freeze
  DROPOUT_STATUSES = %w[rejected withdrawn].freeze

  attr_accessor :status_note, :dropout_reason

  belongs_to :user
  belongs_to :company, inverse_of: :job_applications
  has_many :application_events, dependent: :destroy

  accepts_nested_attributes_for :company, reject_if: ->(attrs) {
    attrs["official_name"].blank? && attrs[:official_name].blank?
  }

  enum :status, STATUSES.index_with(&:itself), default: :reviewed, validate: true
  enum :work_mode, WORK_MODES.index_with(&:itself), validate: { allow_nil: true }
  enum :employment_type, EMPLOYMENT_TYPES.index_with(&:itself), validate: { allow_nil: true }
  enum :contract_type, CONTRACT_TYPES.index_with(&:itself), validate: { allow_nil: true }

  before_validation :normalize_optional_fields
  after_create :record_created_event
  after_update :record_status_change, if: :saved_change_to_status?

  validates :position, presence: true, length: { maximum: 160 }
  validates :company, presence: true
  validates :expected_salary, :offered_salary, length: { maximum: 80 }, allow_blank: true
  validates :link, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :dropout_reason, presence: true, if: :dropout_status_selected?

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
      pattern = "%#{sanitize_sql_like(q)}%"
      left_joins(:company).where(
        "job_applications.position ILIKE :q OR companies.shortcut ILIKE :q OR companies.official_name ILIKE :q",
        q: pattern
      )
    end
  }

  def self.status_options
    statuses.keys
  end

  def company_label
    company&.display_name
  end

  private

  def normalize_optional_fields
    %i[expected_salary offered_salary work_mode employment_type contract_type link email].each do |field|
      value = public_send(field)
      public_send("#{field}=", value.presence)
    end
  end

  def dropout_status_selected?
    DROPOUT_STATUSES.include?(status.to_s) && (new_record? || will_save_change_to_status?)
  end

  def record_created_event
    application_events.create!(
      user: user,
      kind: :status_change,
      to_status: status,
      dropout_reason: dropout_reason.presence,
      body: status_note.presence
    )
  end

  def record_status_change
    application_events.create!(
      user: user,
      kind: :status_change,
      from_status: status_before_last_save,
      to_status: status,
      dropout_reason: dropout_reason.presence,
      body: status_note.presence
    )
  end
end
