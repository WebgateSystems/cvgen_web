# frozen_string_literal: true

module ApplicationHelper
  def app_version_label
    t("app.version", hash: AppIdService.version)
  end

  def theme_options_for_select(themes, selected = nil)
    groups = themes.group_by(&:kind).map do |kind, records|
      label = I18n.t("admin.themes.kinds.#{kind}", default: kind.humanize)
      choices = records.map { |theme| [ theme.name, theme.id, { "data-slug" => theme.slug } ] }
      [ label, choices ]
    end
    grouped_options_for_select(groups, selected)
  end

  def application_status_badge(status)
    {
      "reviewed" => "secondary",
      "applied" => "info",
      "interview" => "primary",
      "offer" => "success",
      "rejected" => "danger",
      "withdrawn" => "warning"
    }.    fetch(status.to_s, "secondary")
  end

  def application_field_value(application, column)
    case column
    when "posted_on"
      application.posted_on ? l(application.posted_on, format: :short) : "—"
    when "status"
      tag.span t("jobseeker.applications.statuses.#{application.status}"),
               class: "badge text-bg-#{application_status_badge(application.status)}"
    when "work_mode"
      application.work_mode.present? ? t("jobseeker.applications.work_modes.#{application.work_mode}") : "—"
    when "employment_type"
      application.employment_type.present? ? t("jobseeker.applications.employment_types.#{application.employment_type}") : "—"
    when "contract_type"
      application.contract_type.present? ? t("jobseeker.applications.contract_types.#{application.contract_type}") : "—"
    when "link"
      if application.link.present?
        link_to application.link, application.link, target: "_blank", rel: "noopener noreferrer"
      else
        "—"
      end
    when "email"
      application.email.present? ? mail_to(application.email) : "—"
    else
      application.public_send(column).presence || "—"
    end
  end
end
