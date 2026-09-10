# frozen_string_literal: true

class ApplicationController < ActionController::Base
  AVAILABLE_LOCALES = %w[en pl].freeze

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_locale

  private

  def set_locale
    I18n.locale = locale_from_cookie.presence&.to_sym || I18n.default_locale
  end

  def locale_from_cookie
    raw = request.get_header("HTTP_COOKIE")
    return if raw.blank?

    parsed = ::Rack::Utils.parse_cookies_header(raw)
    value = parsed["locale"].to_s
    value if AVAILABLE_LOCALES.include?(value)
  end

  def after_sign_in_path_for(resource)
    return admin_root_path if resource.respond_to?(:admin?) && resource.admin?
    return jobseeker_root_path if resource.respond_to?(:can_use_jobseeker_studio?) && resource.can_use_jobseeker_studio?

    stored_location_for(resource) || root_path
  end

  def authenticate_admin!
    authenticate_user!
    return if current_user.admin?

    redirect_to root_path, alert: t("admin.not_authorized")
  end

  def authenticate_jobseeker_studio!
    authenticate_user!
    return if current_user.can_use_jobseeker_studio?

    redirect_to root_path, alert: t("jobseeker.not_authorized")
  end
end
