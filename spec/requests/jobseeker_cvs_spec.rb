# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Jobseeker CV studio", type: :request do
  let(:jobseeker) { create(:user, :jobseeker) }

  before { sign_in jobseeker }

  it "renders the empty studio when the user has no profiles" do
    get jobseeker_cv_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include(I18n.t("jobseeker.cvs.title"))
  end

  it "falls back to default profile metadata when the catalog is empty" do
    create(:cv_profile, user: jobseeker)
    create(:theme)
    allow(Cvgen::Catalog).to receive(:profiles).and_return([])
    allow(Cvgen::Catalog).to receive(:layouts).and_return(%w[modern-stack])

    get jobseeker_cv_path
    expect(response).to have_http_status(:success)
  end

  it "rejects an invalid preview" do
    get jobseeker_cv_preview_path, params: { cv_build: { layout: "modern-stack" } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "returns a downloadable PDF" do
    profile = create(:cv_profile, user: jobseeker)
    theme = create(:theme)
    allow_any_instance_of(CvGenerator).to receive(:build_pdf).and_return(
      pdf: "%PDF-1.4 stub",
      pages: 1,
      scale: 1.0,
      filename: "cv.pdf"
    )

    get jobseeker_cv_preview_path, params: {
      download: "1",
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
    expect(response.headers["Content-Disposition"]).to include("attachment")
  end

  it "surfaces a generator error" do
    profile = create(:cv_profile, user: jobseeker)
    theme = create(:theme)
    allow_any_instance_of(CvGenerator).to receive(:build_pdf).and_raise(CvGenerator::Error, "typst missing")

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

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("typst missing")
  end
end
