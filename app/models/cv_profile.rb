# frozen_string_literal: true

class CvProfile < ApplicationRecord
  DRAFT_STATUSES = %w[idle queued running done failed].freeze

  belongs_to :user, inverse_of: :cv_profiles
  has_many :versions, class_name: "CvProfileVersion", dependent: :destroy, inverse_of: :cv_profile

  accepts_nested_attributes_for :versions

  before_validation :assign_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :user_id }
  validates :draft_status, inclusion: { in: DRAFT_STATUSES }
  # i18n-tasks-use t('activerecord.errors.models.cv_profile.attributes.versions.blank')
  validates :versions, presence: true, on: :create, unless: :drafting?
  validates_associated :versions, on: :create, unless: :drafting?

  def latest_version
    versions.max_by { |version| version.number.to_i }
  end

  def person_name
    latest_version&.person_name
  end

  def drafting?
    draft_status.in?(%w[queued running])
  end

  def draft_failed?
    draft_status == "failed"
  end

  def mark_draft_queued!
    update!(draft_status: "queued", draft_error: nil)
  end

  def mark_draft_running!
    update!(draft_status: "running", draft_error: nil)
  end

  def mark_draft_done!
    update!(draft_status: "done", draft_error: nil)
  end

  def mark_draft_failed!(message)
    update!(draft_status: "failed", draft_error: message)
  end

  private

  def assign_slug
    self.slug = name.to_s.parameterize if slug.blank?
  end
end
