# frozen_string_literal: true

FactoryBot.define do
  factory :theme do
    sequence(:name) { |n| "Theme #{n}" }
    kind { :system }
    file do
      Rack::Test::UploadedFile.new(Cvgen::ROOT.join("themes/modern-blue.yaml").to_s, "text/yaml")
    end

    trait :personal do
      kind { :personal }
      user
    end
  end
end
