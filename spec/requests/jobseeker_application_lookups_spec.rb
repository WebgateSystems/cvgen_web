# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Jobseeker application lookup", type: :request do
  let(:jobseeker) { create(:user, :jobseeker) }

  before { sign_in jobseeker }

  it "offers a manual form and a URL form" do
    get new_jobseeker_application_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include(I18n.t("jobseeker.applications.tabs.manual"))
    expect(response.body).to include(I18n.t("jobseeker.applications.tabs.url"))
    expect(response.body).to include(I18n.t("jobseeker.applications.sections.legend"))
  end

  it "queues a lookup from an offer URL" do
    expect do
      post jobseeker_application_lookups_path, params: {
        application_lookup: { source_url: "https://jobs.example/rails" }
      }
    end.to change(ApplicationLookup, :count).by(1).and have_enqueued_job(ApplicationLookupJob)

    lookup = jobseeker.application_lookups.order(:created_at).last
    expect(response).to redirect_to(jobseeker_application_lookup_path(lookup))
    expect(lookup.status).to eq("queued")
  end

  it "rejects an address that is not http" do
    post jobseeker_application_lookups_path, params: { application_lookup: { source_url: "notaurl" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(I18n.t("jobseeker.applications.tabs.url"))
  end

  it "shows the prefilled form when the lookup is ready" do
    company = create(
      :company,
      official_name: "YND Sp. z o.o.",
      shortcut: "YND",
      street: "Prosta 18",
      city: "Warsaw",
      postal_code: "00-850"
    )
    company.identifiers.create!(kind: "regon", value: "369271291")
    nip = company.identifiers.find_by!(kind: "nip").value
    lookup = ApplicationLookup.create!(
      user: jobseeker,
      source_url: "https://jobs.example/rails",
      status: "ready",
      company: company,
      payload: {
        "position" => "Rails Developer",
        "company_id" => company.id,
        "sections" => [ { "key" => "requirements", "body" => "3 years of Rails" } ]
      }
    )

    get jobseeker_application_lookup_path(lookup)
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Rails Developer")
    expect(response.body).to include("3 years of Rails")
    expect(response.body).to include("lookup-track__step is-done")
    expect(response.body).to include(I18n.t("jobseeker.applications.known_company_legend"))
    expect(response.body).to include("YND")
    expect(response.body).to include("Prosta 18")
    expect(response.body).to include("Warsaw")
    expect(response.body).to include("00-850")
    expect(response.body).to include(nip)
    expect(response.body).to include("369271291")
  end

  it "marks the step where reading failed" do
    lookup = ApplicationLookup.create!(
      user: jobseeker,
      source_url: "https://jobs.example/rails",
      status: "failed",
      step: "reading",
      error: "The model response was not valid JSON."
    )

    get jobseeker_application_lookup_path(lookup)
    expect(response.body).to include("lookup-track__step is-failed")
    expect(response.body).to include("The model response was not valid JSON.")
    expect(response.body).to include(I18n.t("jobseeker.applications.lookup.track.reading"))
  end
end
