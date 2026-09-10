# frozen_string_literal: true

class User < ApplicationRecord
  ROLES = %w[jobseeker recruiter admin].freeze

  has_many :themes, dependent: :destroy
  has_many :cv_profiles, dependent: :destroy, inverse_of: :user

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { jobseeker: "jobseeker", recruiter: "recruiter", admin: "admin" },
       default: :jobseeker, validate: true

  validates :role, inclusion: { in: ROLES }

  def recruiter_or_hr?
    recruiter?
  end

  def can_use_jobseeker_studio?
    admin? || jobseeker?
  end
end
