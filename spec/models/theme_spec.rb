# frozen_string_literal: true

require "rails_helper"

RSpec.describe Theme do
  it "imports system themes from the gem" do
    allow($stdout).to receive(:puts)
    expect { described_class.import_system_from_gem! }.to change(described_class.system, :count).by_at_least(1)
    theme = described_class.system.find_by(slug: "modern-blue")
    expect(theme).to be_present
    expect(theme.parsed_payload).to include("name")
  end

  it "clears the owner on a system theme and requires one for personal themes" do
    owner = create(:user, :jobseeker)
    system_theme = build(:theme, user: owner)
    expect(system_theme).to be_valid
    system_theme.valid?
    expect(system_theme.user_id).to be_nil

    personal = build(:theme, :personal, user: nil)
    expect(personal).not_to be_valid
    expect(personal.errors[:user]).to be_present
  end

  it "keeps slugs unique per kind and owner" do
    create(:theme, name: "Modern Blue")
    duplicate = build(:theme, name: "Modern Blue")
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:slug]).to be_present

    owner = create(:user, :jobseeker)
    create(:theme, :personal, user: owner, name: "Mine")
    expect(build(:theme, :personal, user: owner, name: "Mine")).not_to be_valid
    expect(build(:theme, :personal, user: create(:user, :jobseeker), name: "Mine")).to be_valid
  end

  it "rejects invalid YAML and invalid theme schema" do
    invalid_yaml = Tempfile.new([ "bad", ".yaml" ])
    invalid_yaml.write("{ this is not: yaml")
    invalid_yaml.rewind

    theme = build(:theme, file: Rack::Test::UploadedFile.new(invalid_yaml.path, "text/yaml"))
    expect(theme).not_to be_valid
    expect(theme.errors[:file]).to be_present

    invalid_schema = Tempfile.new([ "schema", ".yaml" ])
    invalid_schema.write({ "name" => "X", "scale" => "nope" }.to_yaml)
    invalid_schema.rewind

    theme = build(:theme, file: Rack::Test::UploadedFile.new(invalid_schema.path, "text/yaml"))
    expect(theme).not_to be_valid
  ensure
    invalid_yaml&.close!
    invalid_schema&.close!
  end

  it "returns no payload when the file is missing" do
    theme = described_class.new
    expect(theme.parsed_payload).to be_nil
  end
end
