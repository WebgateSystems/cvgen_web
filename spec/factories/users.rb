# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123!" }
    role { :jobseeker }

    trait :jobseeker do
      role { :jobseeker }
    end

    trait :recruiter do
      role { :recruiter }
    end

    trait :admin do
      role { :admin }
    end
  end
end
