# frozen_string_literal: true

module Oauth
  module Providers
    CATALOG = {
      google_oauth2: { icon: "google", i18n: "google", kind: "Google" },
      apple: { icon: "apple", i18n: "apple", kind: "Apple" },
      facebook: { icon: "facebook", i18n: "facebook", kind: "Facebook" },
      linkedin: { icon: "linkedin", i18n: "linkedin", kind: "LinkedIn" }
    }.freeze

    module_function

    def enabled_keys
      Devise.omniauth_configs.keys.map(&:to_sym) & CATALOG.keys
    end

    def enabled
      enabled_keys.map { |key| CATALOG.fetch(key).merge(key: key) }
    end

    def kind_for(provider)
      CATALOG.dig(provider.to_sym, :kind) || provider.to_s.humanize
    end
  end
end
