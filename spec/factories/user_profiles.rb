# frozen_string_literal: true

FactoryBot.define do
  factory :user_profile do
    user
    display_name { "Ada Lovelace" }
    location { "London" }
    about { "Mathematician and the first programmer." }
    analysis { UserProfile::Analysis.blank }

    trait :analyzed do
      analyzed_at { Time.current }
      analysis do
        {
          "person_name" => "Ada Lovelace",
          "headline" => "First programmer",
          "summary" => "Notes on the Analytical Engine.",
          "skills" => %w[Mathematics Notes],
          "languages" => [
            { "name" => "English", "level" => "C1" },
            { "name" => "French", "level" => "B2" }
          ],
          "experience" => [
            {
              "company" => "Analytical Engine",
              "role" => "Collaborator",
              "from" => "1842",
              "to" => "1843",
              "highlights" => [ "Bernoulli numbers" ]
            }
          ],
          "education" => [
            { "school" => "Private tutors", "degree" => "Mathematics", "year" => "1834" }
          ],
          "strengths" => [ "Abstraction" ],
          "gaps" => [ "Industry experience" ]
        }
      end
    end
  end
end
