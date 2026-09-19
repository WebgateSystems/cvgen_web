# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OmniAuth callbacks", type: :request do
  def mock_oauth(provider, uid:, email:, name: "Alex Johnson")
    OmniAuth.config.add_mock(
      provider,
      uid: uid,
      info: { email: email, name: name }
    )
  end

  it "registers a new user from Google and opens the studio" do
    mock_oauth(:google_oauth2, uid: "g-new", email: "google@example.com")

    expect do
      get user_google_oauth2_omniauth_callback_path
    end.to change(User, :count).by(1).and change(Identity, :count).by(1)

    expect(response).to redirect_to(jobseeker_root_path)
    expect(User.find_by(email: "google@example.com")).to be_jobseeker
  end

  it "signs an existing Google identity back in" do
    user = create(:user, email: "repeat@example.com")
    create(:identity, user: user, provider: "google_oauth2", uid: "g-repeat")
    mock_oauth(:google_oauth2, uid: "g-repeat", email: "repeat@example.com")

    expect do
      get user_google_oauth2_omniauth_callback_path
    end.not_to change(User, :count)

    expect(response).to redirect_to(jobseeker_root_path)
  end

  it "connects Facebook to an existing email account" do
    create(:user, email: "same@example.com")
    mock_oauth(:facebook, uid: "fb-1", email: "same@example.com", name: "Same Person")

    expect do
      get user_facebook_omniauth_callback_path
    end.to change(Identity, :count).by(1).and change(User, :count).by(0)

    expect(response).to redirect_to(jobseeker_root_path)
  end

  it "signs in through LinkedIn" do
    mock_oauth(:linkedin, uid: "li-1", email: "li@example.com")
    get user_linkedin_omniauth_callback_path
    expect(response).to redirect_to(jobseeker_root_path)
    expect(Identity.find_by(provider: "linkedin", uid: "li-1")).to be_present
  end

  it "signs in through Apple" do
    mock_oauth(:apple, uid: "ap-1", email: "apple@example.com")
    get user_apple_omniauth_callback_path
    expect(response).to redirect_to(jobseeker_root_path)
  end

  it "asks for another method when Apple hides the email" do
    mock_oauth(:apple, uid: "ap-hidden", email: nil)
    get user_apple_omniauth_callback_path
    expect(response).to redirect_to(new_user_registration_path)
    follow_redirect!
    expect(response.body).to include(I18n.t("devise.omniauth_callbacks.missing_email", kind: "Apple"))
  end

  it "returns to login when the provider denies access" do
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
    get user_google_oauth2_omniauth_callback_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "renders OAuth buttons on landing, login, and signup" do
    [ root_path, new_user_session_path, new_user_registration_path ].each do |path|
      get path
      expect(response.body).to include("users/auth/google_oauth2")
      expect(response.body).to include("users/auth/apple")
      expect(response.body).to include("users/auth/facebook")
      expect(response.body).to include("users/auth/linkedin")
      expect(response.body).to include(I18n.t("landing.social_linkedin"))
    end
  end
end
