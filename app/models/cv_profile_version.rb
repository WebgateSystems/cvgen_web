# frozen_string_literal: true

class CvProfileVersion < ApplicationRecord
  belongs_to :cv_profile, inverse_of: :versions

  mount_uploader :file, MarkdownFileUploader

  before_validation :normalize_tag
  before_validation :assign_number, on: :create

  validates :number, presence: true, uniqueness: { scope: :cv_profile_id }
  validates :file, presence: true
  validates :tag, length: { maximum: 80 }, allow_nil: true
  validate :cvgen_markdown_is_valid

  def label
    tag.present? ? "v#{number} · #{tag}" : "v#{number}"
  end

  def parsed_content
    return if file.path.blank? || !File.exist?(file.path)

    Cvgen::Parser.parse(file.path)
  end

  def person_name
    parsed_content&.dig("basics", "name").presence
  rescue Cvgen::SchemaError
    nil
  end

  private

  def normalize_tag
    self.tag = tag.to_s.strip.presence
  end

  def assign_number
    return if number.present? || cv_profile.blank?

    max = cv_profile.versions.reject { |version| version.equal?(self) }.filter_map(&:number).max
    max ||= cv_profile.versions.maximum(:number) if cv_profile.persisted?
    self.number = max.to_i + 1
  end

  def cvgen_markdown_is_valid
    return if file.blank?
    return unless file.path.present? && File.exist?(file.path)

    content = Cvgen::Parser.parse(file.path)
    Cvgen::Schema.validate_content!(content)
  rescue Psych::SyntaxError, Cvgen::SchemaError => e
    errors.add(:file, e.message)
  end
end
