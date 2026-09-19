# frozen_string_literal: true

class User < ApplicationRecord
  ROLES = %w[jobseeker recruiter admin].freeze

  has_one :user_profile, dependent: :destroy, inverse_of: :user
  has_many :themes, dependent: :destroy
  has_many :cv_profiles, dependent: :destroy, inverse_of: :user
  has_many :job_applications, dependent: :destroy
  has_many :company_ratings, dependent: :destroy
  has_many :application_events, dependent: :destroy
  has_many :identities, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable,
         omniauth_providers: %i[google_oauth2 apple facebook linkedin]

  enum :role, { jobseeker: "jobseeker", recruiter: "recruiter", admin: "admin" },
       default: :jobseeker, validate: true

  validates :role, inclusion: { in: ROLES }

  def recruiter_or_hr?
    recruiter?
  end

  def can_use_jobseeker_studio?
    admin? || jobseeker?
  end

  def ensure_user_profile!
    user_profile || create_user_profile!
  rescue ActiveRecord::RecordNotUnique
    reload_user_profile || raise
  end

  def display_name
    user_profile&.display_name.presence ||
      user_profile&.analysis_value("person_name").presence ||
      email.to_s.split("@").first
  end

  def initials
    tokens = display_name.to_s.scan(/[[:alpha:]]+/)
    letters = if tokens.size >= 2
      "#{tokens[0][0]}#{tokens[1][0]}"
    else
      display_name.to_s.gsub(/[^[:alpha:]]/, "")[0, 2]
    end
    letters.to_s.upcase.presence || "?"
  end

  def password_required?
    return false if identities.any?

    super
  end
end
