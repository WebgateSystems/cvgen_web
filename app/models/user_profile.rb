# frozen_string_literal: true

class UserProfile < ApplicationRecord
  STATUSES = %w[idle queued running done failed].freeze

  belongs_to :user, inverse_of: :user_profile
  belongs_to :starter_cv_profile, class_name: "CvProfile", optional: true

  mount_uploader :avatar, AvatarUploader

  before_validation :normalize_analysis

  validates :display_name, length: { maximum: 120 }, allow_blank: true
  validates :location, length: { maximum: 120 }, allow_blank: true
  validates :about, length: { maximum: 5_000 }, allow_blank: true
  validates :analysis_status, inclusion: { in: STATUSES }

  def analysis_hash
    Analysis.normalize(analysis)
  end

  def analysis_value(key)
    analysis_hash[key.to_s]
  end

  def list_text(key)
    Analysis.list_text(analysis_value(key))
  end

  def experience_for_form
    Array(analysis_value("experience"))
  end

  def education_for_form
    Array(analysis_value("education"))
  end

  def languages_for_form
    Array(analysis_value("languages"))
  end

  def contact_for_form
    analysis_value("contact")
  end

  def contact_present?
    contact = contact_for_form
    contact["email"].present? ||
      contact["location"].present? ||
      Array(contact["phones"]).any? ||
      Array(contact["links"]).any?
  end

  def apply_analysis(payload)
    self.analysis = Analysis.normalize(payload)
    self.analyzed_at = Time.current
    self.display_name = analysis_hash["person_name"] if display_name.blank? && analysis_hash["person_name"].present?
    self.about = analysis_hash["summary"] if about.blank? && analysis_hash["summary"].present?
    contact_location = analysis_hash.dig("contact", "location")
    self.location = contact_location if location.blank? && contact_location.present?
    self
  end

  def apply_analysis!(payload)
    apply_analysis(payload)
    save!
  end

  def analysis_present?
    hash = analysis_hash
    hash.fetch_values("person_name", "headline", "summary").any?(&:present?) ||
      hash.dig("contact", "email").present? ||
      hash.dig("contact", "location").present? ||
      Array(hash.dig("contact", "phones")).any? ||
      Array(hash.dig("contact", "links")).any? ||
      hash.fetch_values("skills", "languages", "experience", "education", "strengths", "gaps").any?(&:present?)
  end

  def cv_source_present?
    analysis_present? || about.present? || display_name.present? || location.present?
  end

  def analyzing?
    analysis_status.in?(%w[queued running])
  end

  def progress!(step)
    update!(analysis_status: "running", analysis_step: step, analysis_error: nil)
  end

  def mark_queued!
    update!(analysis_status: "queued", analysis_step: "queued", analysis_error: nil)
  end

  def mark_failed!(message)
    update!(analysis_status: "failed", analysis_step: nil, analysis_error: message)
  end

  def mark_done!
    update!(analysis_status: "done", analysis_step: nil, analysis_error: nil)
  end

  private

  def normalize_analysis
    self.analysis = Analysis.normalize(analysis)
  end
end
