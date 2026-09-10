# frozen_string_literal: true

class CvBuild
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :cv_profile_id, :string
  attribute :cv_profile_version_id, :string
  attribute :theme_id, :string
  attribute :layout, :string, default: "modern-stack"
  attribute :generator_profile, :string, default: "default"
  attribute :scale, :float, default: 1.0
  attribute :fit, :boolean, default: false
  attribute :max_pages, :integer, default: 2
  attribute :max_experience_items, :integer
  attribute :include_skills, :string, default: ""
  attribute :exclude, :string, default: ""

  attr_accessor :user

  validates :user, presence: true
  validates :cv_profile_id, :cv_profile_version_id, :theme_id, presence: true
  validates :layout, :generator_profile, presence: true
  validates :scale, numericality: { greater_than_or_equal_to: 0.6, less_than_or_equal_to: 1.4 }
  validates :max_pages, numericality: { greater_than: 0, less_than_or_equal_to: 8 }
  validate :version_belongs_to_user
  validate :theme_is_available
  validate :layout_exists
  validate :generator_profile_exists

  def profile
    return if user.blank?

    @profile ||= user.cv_profiles.find_by(id: cv_profile_id)
  end

  def version
    return if profile.blank?

    @version ||= profile.versions.find_by(id: cv_profile_version_id)
  end

  def theme
    return if user.blank?

    @theme ||= Theme.for_user(user).find_by(id: theme_id)
  end

  def content_stem
    return "cv" if profile.blank? || version.blank?

    "#{profile.slug}-v#{version.number}"
  end

  def include_skill_list
    include_skills.to_s.split(/[,\n]/).map(&:strip).compact_blank
  end

  def exclude_list
    exclude.to_s.split(/[,\n]/).map(&:strip).compact_blank
  end

  def pdf_filename
    "#{content_stem}.pdf"
  end

  def cli_command
    parts = [
      "bundle exec cv build",
      "-c #{content_stem}",
      "-p #{generator_profile}",
      "-l #{layout}",
      "-t #{theme&.slug.presence || "THEME"}",
      "--scale #{scale}"
    ]
    parts << "--fit" if fit
    parts.join(" \\\n  ")
  end

  def profile_payload
    payload = {
      "name" => generator_profile,
      "layout" => layout,
      "theme" => theme&.slug,
      "max_pages" => max_pages.to_i,
      "include" => include_skill_list.any? ? { "skills" => include_skill_list } : {},
      "exclude" => exclude_list
    }
    payload["max_experience_items"] = max_experience_items if max_experience_items.present?
    payload
  end

  private

  def version_belongs_to_user
    errors.add(:cv_profile_version_id, :invalid) if cv_profile_version_id.present? && version.blank?
  end

  def theme_is_available
    errors.add(:theme_id, :invalid) if theme_id.present? && theme.blank?
  end

  def layout_exists
    return if layout.blank?
    return if Cvgen::Catalog.layouts(Cvgen::ROOT).include?(layout)

    errors.add(:layout, :invalid)
  end

  def generator_profile_exists
    return if generator_profile.blank?
    return if Cvgen::Catalog.profiles(Cvgen::ROOT).include?(generator_profile)

    errors.add(:generator_profile, :invalid)
  end
end
