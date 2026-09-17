# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Jobseeker profiles", type: :request do
  include ActiveJob::TestHelper
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
    expect(response.body).to include(I18n.t("jobseeker.versions.editor_source"))
    expect(response.body).to include("Test Person")
    expect(response.body).to include("md-icon-btn")
    expect(response.body).to include("bi-type-bold")
    expect(response.body).to include(I18n.t("jobseeker.versions.editor_wysiwyg"))
    expect(response.body).to include("md-split__gutter")
    expect(response.body).to include("contenteditable")
    expect(response.body).to include("data-md-studio")
    expect(response.body).to include("display:flex")
    expect(response.body).to include("Software developer")

    get edit_jobseeker_profile_path(profile)
    expect(response).to have_http_status(:success)

    patch jobseeker_profile_path(profile), params: { cv_profile: { name: "SRE" } }
    expect(response).to redirect_to(jobseeker_profile_path(profile))
    expect(profile.reload.name).to eq("SRE")
  end

  it "opens the new profile form" do
    get new_jobseeker_profile_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include(I18n.t("jobseeker.profiles.source_upload"))
    expect(response.body).to include(I18n.t("jobseeker.profiles.from_account"))
    expect(response.body).to include(jobseeker_account_path)
    expect(response.body).to match(/id="source_account"[^>]*disabled/)
  end

  it "offers to draft from My profile when analysis exists" do
    create(:user_profile, :analyzed, user: jobseeker)
    get new_jobseeker_profile_path
    expect(response.body).to include(I18n.t("jobseeker.profiles.from_account_hint"))
    expect(response.body).to match(/id="source_upload"[^>]*checked/)
    expect(response.body).to include("profile-upload-fields")
  end

  it "rejects a profile without a markdown version" do
    post jobseeker_profiles_path, params: { source: "upload", cv_profile: { name: "Empty" } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects drafting from an empty account" do
    post jobseeker_profiles_path, params: { source: "account", cv_profile: { name: "Designer" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(I18n.t("jobseeker.profiles.from_account_empty"))
  end

  it "queues a ChatGPT draft from the account analysis" do
    create(:user_profile, :analyzed, user: jobseeker)
    markdown = Rails.root.join("spec/fixtures/files/cv-sample.md").read
    allow(ChatGpt).to receive(:new).and_return(instance_double(ChatGpt, call: markdown))

    expect do
      post jobseeker_profiles_path, params: {
        source: "account",
        cv_profile: { name: "Software Engineer" }
      }
    end.to change { jobseeker.cv_profiles.count }.by(1).and have_enqueued_job(CvProfileDraftJob)

    profile = jobseeker.cv_profiles.order(:created_at).last
    expect(response).to redirect_to(jobseeker_profiles_path)
    expect(profile.draft_status).to eq("queued")
    expect(profile.versions).to be_empty
    expect(ChatGpt).not_to have_received(:new)

    perform_enqueued_jobs
    expect(profile.reload.draft_status).to eq("done")
    expect(profile.latest_version.tag).to eq(I18n.t("jobseeker.profiles.from_account_tag"))
    expect(ChatGpt).to have_received(:new).with(
      hash_including(prompt: a_string_including("Software Engineer"))
    )
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

  it "saves an edited markdown document as a new version" do
    profile = create(:cv_profile, user: jobseeker)
    markdown = Rails.root.join("spec/fixtures/files/cv-sample.md").read.sub("Test Person", "Ada Lovelace")

    expect do
      post jobseeker_profile_versions_path(profile), params: {
        cv_profile_version: { markdown: markdown, tag: "Edited" }
      }
    end.to change { profile.versions.count }.by(1)

    version = profile.versions.order(:number).last
    expect(response).to redirect_to(jobseeker_profile_path(profile, version_id: version.id))
    expect(version.tag).to eq("Edited")
    expect(version.person_name).to eq("Ada Lovelace")
  end

  it "rejects invalid markdown from the editor" do
    profile = create(:cv_profile, user: jobseeker)
    post jobseeker_profile_versions_path(profile), params: {
      cv_profile_version: { markdown: "not a cv" }
    }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(I18n.t("jobseeker.versions.editor_source"))
  end

  it "does not show another user's profile" do
    other = create(:cv_profile, user: create(:user, :jobseeker))
    get jobseeker_profile_path(other)
    expect(response).to have_http_status(:not_found)
  end
end
