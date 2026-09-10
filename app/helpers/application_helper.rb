# frozen_string_literal: true

module ApplicationHelper
  def theme_options_for_select(themes, selected = nil)
    groups = themes.group_by(&:kind).map do |kind, records|
      label = I18n.t("admin.themes.kinds.#{kind}", default: kind.humanize)
      choices = records.map { |theme| [ theme.name, theme.id, { "data-slug" => theme.slug } ] }
      [ label, choices ]
    end
    grouped_options_for_select(groups, selected)
  end
end
