# frozen_string_literal: true

require "rails_helper"

RSpec.describe Identity do
  it "ties a provider uid to a user" do
    identity = create(:identity, provider: "linkedin", uid: "li-1")
    expect(identity.user).to be_present
    expect(identity).to be_valid
  end

  it "rejects a duplicate provider uid" do
    create(:identity, provider: "facebook", uid: "fb-1")
    other = build(:identity, provider: "facebook", uid: "fb-1")
    expect(other).not_to be_valid
    expect(other.errors[:uid]).to be_present
  end
end
