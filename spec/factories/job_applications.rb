# frozen_string_literal: true

FactoryBot.define do
  factory :job_application do
    user
    company
    sequence(:position) { |n| "Ruby on Rails Developer #{n}" }
    posted_on { Date.new(2026, 2, 3) }
    status { :reviewed }
    expected_salary { "16 000 PLN netto" }
    work_mode { :remote }
    employment_type { :full_time }
    contract_type { :b2b }
    link { "https://example.com/jobs/rails" }
    email { "jobs@example.com" }
  end
end
