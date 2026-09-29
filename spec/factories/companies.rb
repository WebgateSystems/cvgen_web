# frozen_string_literal: true

FactoryBot.define do
  sequence(:company_nip) { |n| format("%010d", n) }

  factory :company do
    sequence(:official_name) { |n| "Acme #{n} Sp. z o.o." }
    sequence(:shortcut) { |n| "ACM#{n}" }
    kind { :employer }
    country { "PL" }
    street { "Prosta 18" }
    city { "Warsaw" }
    postal_code { "00-850" }

    after(:build) do |company|
      next if company.identifiers.any?

      company.identifiers.build(kind: :nip, value: generate(:company_nip))
    end

    trait :agency do
      kind { :agency }
    end
  end
end
