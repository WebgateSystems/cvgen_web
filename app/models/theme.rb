# frozen_string_literal: true

class Theme < ApplicationRecord
  KINDS = %w[system personal].freeze

  belongs_to :user, optional: true

  mount_uploader :file, ThemeFileUploader

  enum :kind, { system: "system", personal: "personal" }, default: :system, validate: true

  before_validation :normalize_assignment
  before_validation :assign_slug
  before_validation :assign_file_from_yaml_text

  validates :name, presence: true
  validates :slug, presence: true
  # i18n-tasks-use t('activerecord.errors.models.theme.attributes.file.blank')
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

  def yaml_text
    return @yaml_text unless @yaml_text.nil?
    return if file.path.blank? || !File.exist?(file.path)

    File.read(file.path)
  end

  def yaml_text=(value)
    @yaml_text = value
  end

  def parsed_payload
    return parsed_yaml_text if @yaml_text.present?
    return if file.path.blank? || !File.exist?(file.path)

    raw = YAML.safe_load_file(file.path, permitted_classes: []) || {}
    Cvgen::Theme.deep_stringify(raw)
  end

  def heading_font
    parsed_payload&.dig("fonts", "heading").to_s
  end

  def body_font
    parsed_payload&.dig("fonts", "body").to_s
  end

  private

  def normalize_assignment
    self.user_id = nil if system?
  end

  def assign_slug
    source = name.presence || file.identifier.presence || file.filename
    self.slug = source.to_s.sub(/\.(ya?ml)\z/i, "").parameterize if slug.blank?
  end

  def assign_file_from_yaml_text
    return if @yaml_text.nil?

    @yaml_text = ThemeYaml.patch(@yaml_text, name: name)
    @yaml_io = Tempfile.new([ "theme", ".yaml" ])
    @yaml_io.write(@yaml_text)
    @yaml_io.flush
    @yaml_io.rewind
    self.file = @yaml_io
  end

  def parsed_yaml_text
    raw = YAML.safe_load(@yaml_text, permitted_classes: []) || {}
    Cvgen::Theme.deep_stringify(raw)
  rescue Psych::SyntaxError
    nil
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
    if @yaml_text.present?
      YAML.safe_load(@yaml_text, permitted_classes: [])
    end
    return if file.blank?
    return unless file.path.present? && File.exist?(file.path)

    data = parsed_payload || {}
    data["name"] ||= name.presence || slug
    data["scale"] = data.key?("scale") ? Float(data["scale"]) : 1.0
    Cvgen::Schema.validate_theme!(data)
  rescue Psych::SyntaxError
    # i18n-tasks-use t('activerecord.errors.models.theme.attributes.file.invalid_yaml')
    # i18n-tasks-use t('activerecord.errors.models.theme.attributes.yaml_text.invalid_yaml')
    errors.add(:file, :invalid_yaml)
    errors.add(:yaml_text, :invalid_yaml) if @yaml_text.present?
  rescue Cvgen::SchemaError, ArgumentError, TypeError => e
    errors.add(:file, e.message)
    errors.add(:yaml_text, e.message) if @yaml_text.present?
  end
end
