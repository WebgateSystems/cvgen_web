# frozen_string_literal: true

class CvProfile < ApplicationRecord
  belongs_to :user, inverse_of: :cv_profiles
  has_many :versions, class_name: "CvProfileVersion", dependent: :destroy, inverse_of: :cv_profile

  accepts_nested_attributes_for :versions

  before_validation :assign_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :user_id }
  # i18n-tasks-use t('activerecord.errors.models.cv_profile.attributes.versions.blank')
  validates :versions, presence: true, on: :create
  validates_associated :versions, on: :create

  def latest_version
    versions.max_by { |version| version.number.to_i }
  end

  def person_name
    latest_version&.person_name
  end

  private

  def assign_slug
    self.slug = name.to_s.parameterize if slug.blank?
  end
end
