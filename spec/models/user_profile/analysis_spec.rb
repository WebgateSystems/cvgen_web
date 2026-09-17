# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserProfile::Analysis do
  it "normalizes a ChatGPT-shaped payload" do
    result = described_class.normalize(
      person_name: " Ada ",
      skills: [ "Ruby", "", "Rails" ],
      experience: [
        { company: "Acme", role: "Dev", from: "2020", to: "2022", highlights: [ "Shipped v1" ] },
        { company: "", role: "", from: "", to: "", highlights: [] }
      ],
      education: [ { school: "MIT", degree: "", year: "" } ]
    )

    expect(result["person_name"]).to eq("Ada")
    expect(result["skills"]).to eq(%w[Ruby Rails])
    expect(result["experience"]).to eq(
      [ { "company" => "Acme", "role" => "Dev", "from" => "2020", "to" => "2022", "highlights" => [ "Shipped v1" ] } ]
    )
    expect(result["education"]).to eq([ { "school" => "MIT", "degree" => "", "year" => "" } ])
  end

  it "normalizes languages with levels from objects or printed lines" do
    objects = described_class.normalize(
      languages: [ { name: "English", level: "C1" }, { name: "French", level: "" } ]
    )
    expect(objects["languages"]).to eq(
      [
        { "name" => "English", "level" => "C1" },
        { "name" => "French", "level" => "" }
      ]
    )

    lines = described_class.normalize(languages: [ "Polish (native)", "English - C1" ])
    expect(lines["languages"]).to contain_exactly(
      { "name" => "Polish", "level" => "native" },
      { "name" => "English", "level" => "C1" }
    )
  end

  it "pulls contact details from a nested object or from flat CV fields" do
    nested = described_class.normalize(
      contact: {
        email: "ada@example.com",
        location: "London",
        phones: [ { label: "Mobile", number: "+44 7123 456789" } ],
        links: [ { label: "LinkedIn", url: "https://linkedin.com/in/ada" } ]
      }
    )
    expect(nested["contact"]).to eq(
      "email" => "ada@example.com",
      "location" => "London",
      "phones" => [ { "label" => "Mobile", "number" => "+44 7123 456789" } ],
      "links" => [ { "label" => "LinkedIn", "url" => "https://linkedin.com/in/ada" } ]
    )

    flat = described_class.normalize(
      email: "ada@example.com",
      phone: "+44 7123 456789",
      location: "London",
      linkedin: "https://linkedin.com/in/ada",
      github: "https://github.com/ada"
    )
    expect(flat["contact"]["email"]).to eq("ada@example.com")
    expect(flat["contact"]["phones"].sole["number"]).to eq("+44 7123 456789")
    expect(flat["contact"]["links"].map { |link| link["label"] }).to contain_exactly("LinkedIn", "GitHub")
  end

  it "maps form textareas and indexed rows into the schema" do
    result = described_class.from_form(
      "person_name" => "Ada",
      "skills_text" => "Ruby\nRails",
      "languages_text" => "English",
      "strengths_text" => "",
      "gaps_text" => "Public speaking",
      "experience" => {
        "0" => { "company" => "Acme", "role" => "Dev", "from" => "2020", "to" => "now", "highlights_text" => "API\nLedger" },
        "1" => { "company" => "", "role" => "", "from" => "", "to" => "", "highlights_text" => "" }
      },
      "education" => {
        "0" => { "school" => "", "degree" => "", "year" => "" }
      }
    )

    expect(result["skills"]).to eq(%w[Ruby Rails])
    expect(result["languages"]).to eq([ { "name" => "English", "level" => "" } ])
    expect(result["gaps"]).to eq([ "Public speaking" ])
    expect(result["experience"].sole["highlights"]).to eq(%w[API Ledger])
    expect(result["education"]).to eq([])
  end
end
