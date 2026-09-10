# frozen_string_literal: true

class Theme < ApplicationRecord
  KINDS = %w[system personal].freeze

  belongs_to :user, optional: true

  mount_uploader :file, ThemeFileUploader

  enum :kind, { system: "system", personal: "personal" }, default: :system, validate: true

  before_validation :normalize_assignment
  before_validation :assign_slug

  validates :name, presence: true
  validates :slug, presence: true
  validates :file, presence: true
  validates :kind, inclusion: { in: KINDS }
  validate :personal_theme_needs_owner
  validate :slug_is_unique_for_kind
  validate :cvgen_yaml_is_valid

  scope :for_user, ->(user) { where(kind: :system).or(where(user: user)) }

  def self.import_system_from_gem!
    raise "cvgen gem is not loaded" unless defined?(Cvgen::ROOT)

    Dir[Cvgen::ROOT.join("themes", "*.{yaml,yml}")].sort.each do |path|
      slug = File.basename(path, ".*")
      theme = find_or_initialize_by(kind: :system, slug: slug, user_id: nil)
      parsed = YAML.safe_load_file(path, permitted_classes: []) || {}
      theme.name = parsed["name"].presence || slug.tr("-", " ").titleize
      File.open(path, "rb") { |io| theme.file = io }
      theme.save!
      puts "Seeded system theme #{theme.slug}"
    end
  end

  def parsed_payload
    return if file.path.blank? || !File.exist?(file.path)

    raw = YAML.safe_load_file(file.path, permitted_classes: []) || {}
    Cvgen::Theme.deep_stringify(raw)
  end

  private

  def normalize_assignment
    self.user_id = nil if system?
  end

  def assign_slug
    source = name.presence || file.identifier.presence || file.filename
    self.slug = source.to_s.sub(/\.(ya?ml)\z/i, "").parameterize if slug.blank?
  end

  def personal_theme_needs_owner
    errors.add(:user, :blank) if personal? && user_id.blank?
  end

  def slug_is_unique_for_kind
    return if slug.blank?

    scope = if system?
      Theme.system.where(slug: slug)
    else
      Theme.personal.where(slug: slug, user_id: user_id)
    end
    scope = scope.where.not(id: id) if persisted?
    errors.add(:slug, :taken) if scope.exists?
  end

  def cvgen_yaml_is_valid
    return if file.blank?
    return unless file.path.present? && File.exist?(file.path)

    data = parsed_payload || {}
    data["name"] ||= name.presence || slug
    data["scale"] = data.key?("scale") ? Float(data["scale"]) : 1.0
    Cvgen::Schema.validate_theme!(data)
  rescue Psych::SyntaxError
    errors.add(:file, :invalid_yaml)
  rescue Cvgen::SchemaError, ArgumentError, TypeError => e
    errors.add(:file, e.message)
  end
end
