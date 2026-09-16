# frozen_string_literal: true

FactoryBot.define do
  factory :company do
    sequence(:official_name) { |n| "Acme #{n} Sp. z o.o." }
    sequence(:shortcut) { |n| "ACM#{n}" }
    kind { :employer }
    country { "PL" }
    legal_id_kind { :nip }
    sequence(:legal_id) { |n| format("%010d", n) }
    street { "Prosta 18" }
    city { "Warsaw" }
    postal_code { "00-850" }

    trait :agency do
      kind { :agency }
    end
  end
end
