# frozen_string_literal: true

class ApplicationEvent < ApplicationRecord
  KINDS = %w[status_change message].freeze
  DROPOUT_REASONS = %w[ghosting no_offer candidate_withdrew process_joke other].freeze

  belongs_to :job_application
  belongs_to :user

  enum :kind, KINDS.index_with(&:itself), validate: true

  validates :kind, inclusion: { in: KINDS }
  validates :body, presence: true, if: :message?
  validates :dropout_reason, inclusion: { in: DROPOUT_REASONS }, allow_blank: true
  validates :body, length: { maximum: 5000 }, allow_blank: true

  scope :chronological, -> { order(created_at: :asc, id: :asc) }
end
