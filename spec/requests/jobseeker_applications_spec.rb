# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Jobseeker applications", type: :request do
  let(:jobseeker) { create(:user, :jobseeker) }

  before { sign_in jobseeker }

  it "lists applications and status totals" do
    create(:job_application, user: jobseeker, company: "YND", status: :reviewed)
    create(:job_application, user: jobseeker, company: "Acme", status: :applied)
    create(:job_application, user: create(:user, :jobseeker), company: "Hidden")

    get jobseeker_applications_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("YND")
    expect(response.body).to include("Acme")
    expect(response.body).not_to include("Hidden")
    expect(response.body).to include(I18n.t("jobseeker.applications.columns"))
    expect(response.body).not_to include(I18n.t("admin.users.edit"))
  end

  it "paginates the index to 30 rows and serves the next page as rows" do
    31.times do |index|
      create(:job_application, user: jobseeker, company: "Co #{index}", updated_at: index.minutes.ago)
    end
    create(:job_application, user: jobseeker, company: "Fresh Corp", updated_at: Time.current)

    get jobseeker_applications_path
    expect(response.body.scan('class="application-row"').size).to eq(30)
    expect(response.body).to include("Fresh Corp")
    expect(response.body).not_to include("Co 30")

    get jobseeker_applications_path, params: { rows: "1", page: 2 }
    expect(response).to have_http_status(:success)
    expect(response.body.scan('class="application-row"').size).to eq(2)
    expect(response.headers["X-Has-More"]).to eq("0")
  end

  it "filters the index by company or position from three characters" do
    create(:job_application, user: jobseeker, position: "Regular Ruby Developer", company: "YND")
    create(:job_application, user: jobseeker, position: "Java Engineer", company: "Acme")

    get jobseeker_applications_path, params: { q: "YN" }
    expect(response.body).to include("YND")
    expect(response.body).to include("Acme")

    get jobseeker_applications_path, params: { q: "YND" }
    expect(response.body).to include("YND")
    expect(response.body).not_to include("Acme")
  end

  it "opens a show page with every field" do
    application = create(
      :job_application,
      user: jobseeker,
      position: "Regular Ruby Developer",
      company: "YND",
      expected_salary: "16 000 PLN",
      email: "hr@ynd.example"
    )

    get jobseeker_application_path(application)
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Regular Ruby Developer")
    expect(response.body).to include("YND")
    expect(response.body).to include("16 000 PLN")
    expect(response.body).to include("hr@ynd.example")
  end

  it "filters by status" do
    create(:job_application, user: jobseeker, company: "YND", status: :reviewed)
    create(:job_application, user: jobseeker, company: "Acme", status: :applied)

    get jobseeker_applications_path, params: { status: "applied" }
    expect(response.body).to include("Acme")
    expect(response.body).not_to include("YND")
  end

  it "creates, updates, and deletes an application" do
    get new_jobseeker_application_path
    expect(response).to have_http_status(:success)

    expect do
      post jobseeker_applications_path, params: {
        job_application: {
          position: "Regular Ruby Developer",
          company: "YND",
          posted_on: "2026-02-03",
          status: "reviewed",
          expected_salary: "11 000 – 17 500 PLN",
          work_mode: "onsite",
          employment_type: "full_time",
          contract_type: "b2b",
          link: "https://example.com/ynd",
          email: "hr@ynd.example"
        }
      }
    end.to change { jobseeker.job_applications.count }.by(1)

    application = jobseeker.job_applications.order(:created_at).last
    expect(response).to redirect_to(jobseeker_applications_path)

    get edit_jobseeker_application_path(application)
    expect(response).to have_http_status(:success)

    patch jobseeker_application_path(application), params: {
      job_application: { status: "interview", offered_salary: "18 000 PLN" }
    }
    expect(application.reload).to be_interview
    expect(application.offered_salary).to eq("18 000 PLN")

    expect { delete jobseeker_application_path(application) }.to change { jobseeker.job_applications.count }.by(-1)
  end

  it "rejects an invalid application" do
    post jobseeker_applications_path, params: { job_application: { position: "", company: "" } }
    expect(response).to have_http_status(:unprocessable_content)

    application = create(:job_application, user: jobseeker)
    patch jobseeker_application_path(application), params: { job_application: { position: "" } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "does not show another user's application" do
    other = create(:job_application)
    get edit_jobseeker_application_path(other)
    expect(response).to have_http_status(:not_found)
  end

  it "shows the tracker count on the dashboard" do
    create(:job_application, user: jobseeker)
    get jobseeker_root_path
    expect(response.body).to include(I18n.t("jobseeker.applications.title"))
  end
end
