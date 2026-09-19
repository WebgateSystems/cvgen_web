# frozen_string_literal: true

require "openssl"
require "omniauth-google-oauth2"
require "omniauth-apple"
require "omniauth-facebook"
require "omniauth-linkedin-oauth2"

OmniAuth.config.allowed_request_methods = %i[post]
OmniAuth.config.silence_get_warning = true

oauth_setting = lambda do |provider, key|
  Settings.oauth&.public_send(provider)&.public_send(key).to_s.presence
end

apple_pem = lambda do
  raw = oauth_setting.call("apple", "private_key").to_s.gsub('\\n', "\n")
  return raw if raw.include?("BEGIN")
  return OpenSSL::PKey::EC.generate("prime256v1").to_pem unless Rails.env.production?

  nil
end

Devise.setup do |config|
  google_id = oauth_setting.call("google", "client_id")
  google_secret = oauth_setting.call("google", "client_secret")
  if google_id.present? && google_secret.present?
    config.omniauth :google_oauth2, google_id, google_secret,
                    scope: "email,profile",
                    prompt: "select_account",
                    access_type: "online"
  end

  facebook_id = oauth_setting.call("facebook", "app_id")
  facebook_secret = oauth_setting.call("facebook", "app_secret")
  if facebook_id.present? && facebook_secret.present?
    config.omniauth :facebook, facebook_id, facebook_secret,
                    scope: "email,public_profile",
                    info_fields: "email,name"
  end

  linkedin_id = oauth_setting.call("linkedin", "client_id")
  linkedin_secret = oauth_setting.call("linkedin", "client_secret")
  if linkedin_id.present? && linkedin_secret.present?
    config.omniauth :linkedin, linkedin_id, linkedin_secret,
                    scope: "openid profile email"
  end

  apple_id = oauth_setting.call("apple", "client_id")
  apple_team = oauth_setting.call("apple", "team_id")
  apple_key = oauth_setting.call("apple", "key_id")
  pem = apple_pem.call
  if apple_id.present? && apple_team.present? && apple_key.present? && pem.present?
    config.omniauth :apple, apple_id, "", {
      scope: "email name",
      team_id: apple_team,
      key_id: apple_key,
      pem: pem
    }
  end
end
