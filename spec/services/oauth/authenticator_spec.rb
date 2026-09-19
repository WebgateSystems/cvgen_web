# frozen_string_literal: true

require "rails_helper"

RSpec.describe Oauth::Authenticator do
  def auth(provider: "google_oauth2", uid: "g-1", email: "alex@example.com", name: "Alex Johnson")
    OmniAuth::AuthHash.new(
      provider: provider,
      uid: uid,
      info: { email: email, name: name }
    )
  end

  it "creates a jobseeker and identity from a new social login" do
    user = described_class.call(auth)
    expect(user).to be_persisted
    expect(user).to be_jobseeker
    expect(user.email).to eq("alex@example.com")
    expect(user.identities.sole.provider).to eq("google_oauth2")
    expect(user.identities.sole.uid).to eq("g-1")
  end

  it "reuses the identity on the next login" do
    first = described_class.call(auth)
    second = described_class.call(auth)
    expect(second).to eq(first)
    expect(Identity.where(provider: "google_oauth2", uid: "g-1").count).to eq(1)
  end

  it "links a known email to the existing account" do
    existing = create(:user, email: "alex@example.com")
    user = described_class.call(auth(provider: "apple", uid: "ap-9"))
    expect(user).to eq(existing)
    expect(existing.identities.sole.provider).to eq("apple")
  end

  it "returns nil when the provider hides the email" do
    expect(described_class.call(auth(email: nil, uid: "hidden"))).to be_nil
    expect(User.count).to eq(0)
  end
end
