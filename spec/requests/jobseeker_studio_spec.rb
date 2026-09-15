# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Jobseeker studio", type: :request do
  def markdown_upload
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/files/cv-sample.md"),
      "text/markdown"
    )
  end

  it "lets a jobseeker open the studio" do
    sign_in create(:user, :jobseeker)
    allow(AppIdService).to receive(:version).and_return("bd56dabe")
    get jobseeker_root_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include(I18n.t("jobseeker.dashboard"))
    expect(response.body).to include(I18n.t("app.version", hash: "bd56dabe"))
  end

  it "lets an admin switch into the studio" do
    sign_in create(:user, :admin)

    get jobseeker_root_path
    expect(response).to have_http_status(:success)

    get admin_root_path
    expect(response).to have_http_status(:success)
  end

  it "blocks a recruiter from the studio" do
    sign_in create(:user, :recruiter)
    get jobseeker_root_path

    expect(response).to redirect_to(root_path)
  end

  it "lets a jobseeker create a versioned profile" do
    jobseeker = create(:user, :jobseeker)
    sign_in jobseeker

    expect do
      post jobseeker_profiles_path, params: {
        cv_profile: {
          name: "Software Engineer",
          versions_attributes: {
            "0" => { file: markdown_upload, tag: "Acme" }
          }
        }
      }
    end.to change { jobseeker.cv_profiles.count }.by(1)

    profile = jobseeker.cv_profiles.last
    version = profile.latest_version
    expect(response).to redirect_to(jobseeker_profile_path(profile))
    expect(profile.name).to eq("Software Engineer")
    expect(version.number).to eq(1)
    expect(version.tag).to eq("Acme")
    expect(version.person_name).to eq("Test Person")
  end

  it "lets a jobseeker add a tagged version to a profile" do
    jobseeker = create(:user, :jobseeker)
    profile = create(:cv_profile, user: jobseeker, name: "DevOps")
    sign_in jobseeker

    expect do
      post jobseeker_profile_versions_path(profile), params: {
        cv_profile_version: { file: markdown_upload, tag: "Globex" }
      }
    end.to change { profile.versions.count }.by(1)

    version = profile.versions.order(:number).last
    expect(response).to redirect_to(jobseeker_profile_path(profile))
    expect(version.number).to eq(2)
    expect(version.tag).to eq("Globex")
    expect(version.label).to eq("v2 · Globex")
  end

  it "opens the CV studio" do
    jobseeker = create(:user, :jobseeker)
    create(:cv_profile, user: jobseeker, name: "Software Engineer")
    create(:theme)
    sign_in jobseeker

    get jobseeker_cv_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include(I18n.t("jobseeker.cvs.title"))
    expect(response.body).to include("bundle exec cv build")
  end

  it "returns a generated PDF preview" do
    jobseeker = create(:user, :jobseeker)
    profile = create(:cv_profile, user: jobseeker, name: "Software Engineer")
    theme = create(:theme)
    sign_in jobseeker

    allow_any_instance_of(CvGenerator).to receive(:build_pdf).and_return(
      pdf: "%PDF-1.4 stub",
      pages: 1,
      scale: 1.0,
      filename: "software-engineer-v1.pdf"
    )

    get jobseeker_cv_preview_path, params: {
      cv_build: {
        cv_profile_id: profile.id,
        cv_profile_version_id: profile.latest_version.id,
        theme_id: theme.id,
        layout: "modern-stack",
        generator_profile: "default",
        scale: 1.0
      }
    }

    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq("application/pdf")
  end
end
