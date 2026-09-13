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

  it "keeps an explicit uuid and treats recruiters as HR" do
    id = SecureRandom.uuid
    user = create(:user, :recruiter, id: id)
    expect(user.id).to eq(id)
    expect(user.recruiter_or_hr?).to be(true)
    expect(build(:user, :jobseeker).recruiter_or_hr?).to be(false)
  end
end
