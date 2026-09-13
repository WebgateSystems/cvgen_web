# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication", type: :request do
  it "sends an admin to the admin panel after login" do
    admin = create(:user, :admin, password: "password123!")
    post user_session_path, params: { user: { email: admin.email, password: "password123!" } }
    expect(response).to redirect_to(admin_root_path)
  end

  it "sends a jobseeker to the studio after login" do
    jobseeker = create(:user, :jobseeker, password: "password123!")
    post user_session_path, params: { user: { email: jobseeker.email, password: "password123!" } }
    expect(response).to redirect_to(jobseeker_root_path)
  end

  it "asks guests to sign in before admin or studio" do
    get admin_root_path
    expect(response).to redirect_to(new_user_session_path)

    get jobseeker_root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "sends a recruiter to the landing page after login" do
    recruiter = create(:user, :recruiter, password: "password123!")
    post user_session_path, params: { user: { email: recruiter.email, password: "password123!" } }
    expect(response).to redirect_to(root_path)
  end
end
