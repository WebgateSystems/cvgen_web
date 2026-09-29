# frozen_string_literal: true

class ThemeCloner
  # i18n-tasks-use t('jobseeker.themes.copy_name')
  def self.call(source:, user:)
    name = unique_name(user, I18n.t("jobseeker.themes.copy_name", name: source.name))
    yaml = File.read(source.file.path)
    theme = user.themes.new(kind: :personal, user: user, name: name, yaml_text: yaml)
    theme.save!
    theme
  end

  def self.unique_name(user, base)
    candidate = base
    index = 2
    while user.themes.personal.exists?(slug: candidate.parameterize)
      candidate = "#{base} #{index}"
      index += 1
    end
    candidate
  end
  private_class_method :unique_name
end
