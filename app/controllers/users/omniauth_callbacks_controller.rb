# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :apple
  skip_before_action :block_non_modern_browsers, raise: false

  Oauth::Providers::CATALOG.each_key do |provider|
    define_method(provider) { complete_sign_in(provider) }
  end

  def failure
    redirect_to new_user_session_path, alert: t(
      "devise.omniauth_callbacks.failure",
      kind: Oauth::Providers.kind_for(failed_strategy&.name),
      reason: failure_message
    )
  end

  private

  def complete_sign_in(provider)
    user = Oauth::Authenticator.call(request.env["omniauth.auth"])
    kind = Oauth::Providers.kind_for(provider)

    unless user
      redirect_to new_user_registration_path, alert: t("devise.omniauth_callbacks.missing_email", kind: kind)
      return
    end

    sign_in_and_redirect user, event: :authentication
    flash[:notice] = t("devise.omniauth_callbacks.success", kind: kind) if is_navigational_format?
  end
end
