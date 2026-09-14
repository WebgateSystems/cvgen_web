# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Jobseeker profiles", type: :request do
  let(:jobseeker) { create(:user, :jobseeker) }

  before { sign_in jobseeker }

  it "lists, shows, and edits a profile" do
    profile = create(:cv_profile, user: jobseeker, name: "DevOps")

    get jobseeker_profiles_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("DevOps")

    get jobseeker_profile_path(profile)
    expect(response).to have_http_status(:success)
    expect(response.body).to include("v1")

    get edit_jobseeker_profile_path(profile)
    expect(response).to have_http_status(:success)

    patch jobseeker_profile_path(profile), params: { cv_profile: { name: "SRE" } }
    expect(response).to redirect_to(jobseeker_profile_path(profile))
    expect(profile.reload.name).to eq("SRE")
  end

  it "opens the new profile form" do
    get new_jobseeker_profile_path
    expect(response).to have_http_status(:success)
  end

  it "rejects a profile without a markdown version" do
    post jobseeker_profiles_path, params: { cv_profile: { name: "Empty" } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects an invalid profile update" do
    profile = create(:cv_profile, user: jobseeker)
    patch jobseeker_profile_path(profile), params: { cv_profile: { name: "" } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "deletes a profile" do
    profile = create(:cv_profile, user: jobseeker)
    expect { delete jobseeker_profile_path(profile) }.to change { jobseeker.cv_profiles.count }.by(-1)
    expect(response).to redirect_to(jobseeker_profiles_path)
  end

  it "adds a version and refuses to delete the last one" do
    profile = create(:cv_profile, user: jobseeker)
    get new_jobseeker_profile_version_path(profile)
    expect(response).to have_http_status(:success)

    post jobseeker_profile_versions_path(profile), params: {
      cv_profile_version: { file: invalid_markdown_upload }
    }
    expect(response).to have_http_status(:unprocessable_content)

    first = profile.versions.first
    delete jobseeker_profile_version_path(profile, first)
    expect(response).to redirect_to(jobseeker_profile_path(profile))
    expect(profile.versions.count).to eq(1)

    post jobseeker_profile_versions_path(profile), params: {
      cv_profile_version: { file: markdown_upload, tag: "Acme" }
    }
    second = profile.versions.order(:number).last
    expect { delete jobseeker_profile_version_path(profile, second) }.to change { profile.versions.count }.by(-1)
  end

  it "does not show another user's profile" do
    other = create(:cv_profile, user: create(:user, :jobseeker))
    get jobseeker_profile_path(other)
    expect(response).to have_http_status(:not_found)
  end
end
