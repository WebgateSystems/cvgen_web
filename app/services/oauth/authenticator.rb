# frozen_string_literal: true

module Oauth
  class Authenticator
    def self.call(auth)
      new(auth).connect
    end

    def initialize(auth)
      @auth = auth
    end

    def connect
      return existing_identity.user if existing_identity

      user = find_or_create_user
      return unless user

      attach_identity(user)
      user
    rescue ActiveRecord::RecordNotUnique
      Identity.find_by!(provider: provider, uid: uid).user
    end

    private

    attr_reader :auth

    def existing_identity
      @existing_identity ||= Identity.find_by(provider: provider, uid: uid)
    end

    def provider
      auth.provider.to_s
    end

    def uid
      auth.uid.to_s
    end

    def email
      auth.info&.email.to_s.strip.downcase.presence
    end

    def name
      auth.info&.name.presence ||
        [ auth.info&.first_name, auth.info&.last_name ].compact.join(" ").presence
    end

    def find_or_create_user
      return if email.blank?

      User.find_by("LOWER(email) = ?", email) || create_user
    end

    def create_user
      User.create!(
        email: email,
        password: Devise.friendly_token[0, 24],
        role: :jobseeker
      )
    end

    def attach_identity(user)
      user.identities.create!(
        provider: provider,
        uid: uid,
        email: email,
        name: name
      )
    end
  end
end
