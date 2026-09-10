# frozen_string_literal: true

FactoryBot.define do
  factory :cv_profile do
    user
    sequence(:name) { |n| "Software Engineer #{n}" }

    after(:build) do |profile|
      next if profile.versions.any?

      profile.versions.build(
        file: Rack::Test::UploadedFile.new(
          Rails.root.join("spec/fixtures/files/cv-sample.md"),
          "text/markdown"
        )
      )
    end
  end
end
