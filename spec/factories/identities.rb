# frozen_string_literal: true

FactoryBot.define do
  factory :identity do
    user
    provider { "google_oauth2" }
    sequence(:uid) { |n| "uid-#{n}" }
    email { user.email }
    name { "Alex Johnson" }
  end
end
