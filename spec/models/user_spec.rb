# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  it "defaults new users to jobseeker" do
    user = described_class.new(email: "new@example.com", password: "password123!")
    expect(user).to be_jobseeker
  end

  it "accepts recruiter and admin roles" do
    expect(build(:user, :recruiter)).to be_recruiter
    expect(build(:user, :admin)).to be_admin
  end

  it "lets admin and jobseeker use the studio, but not recruiter" do
    expect(build(:user, :admin).can_use_jobseeker_studio?).to be(true)
    expect(build(:user, :jobseeker).can_use_jobseeker_studio?).to be(true)
    expect(build(:user, :recruiter).can_use_jobseeker_studio?).to be(false)
  end

  it "uses a uuid primary key" do
    user = create(:user)
    expect(user.id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
  end

  it "falls back to the email local-part for display name and initials" do
    user = build(:user, email: "ada.lovelace@example.com")
    expect(user.display_name).to eq("ada.lovelace")
    expect(user.initials).to eq("AL")
  end

  it "prefers the account profile name" do
    user = create(:user, email: "other@example.com")
    create(:user_profile, user: user, display_name: "Ada Lovelace")
    expect(user.reload.display_name).to eq("Ada Lovelace")
    expect(user.initials).to eq("AL")
  end

  it "creates an account profile once" do
    user = create(:user)
    first = user.ensure_user_profile!
    expect(user.ensure_user_profile!).to eq(first)
  end

  it "does not require a password when the user signed in socially" do
    user = create(:user)
    create(:identity, user: user)
    user.reload
    user.password = nil
    user.password_confirmation = nil
    expect(user).to be_valid
  end

  it "keeps an explicit uuid and treats recruiters as HR" do
    id = SecureRandom.uuid
    user = create(:user, :recruiter, id: id)
    expect(user.id).to eq(id)
    expect(user.recruiter_or_hr?).to be(true)
    expect(build(:user, :jobseeker).recruiter_or_hr?).to be(false)
  end
end
