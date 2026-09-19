# frozen_string_literal: true

module OauthHelper
  def oauth_providers
    Oauth::Providers.enabled
  end
end
