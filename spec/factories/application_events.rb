# frozen_string_literal: true

FactoryBot.define do
  factory :application_event do
    job_application
    user { job_application.user }
    kind { :message }
    body { "Sent a follow-up." }

    trait :status_change do
      kind { :status_change }
      from_status { "applied" }
      to_status { "interview" }
      body { nil }
    end
  end
end
