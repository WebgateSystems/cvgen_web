# frozen_string_literal: true

FactoryBot.define do
  factory :company_rating do
    company
    user
    responsiveness { 4 }
    seriousness { 3 }
    human_process { 5 }
    fairness { 4 }
    comment { "Replied within a week." }
  end
end
