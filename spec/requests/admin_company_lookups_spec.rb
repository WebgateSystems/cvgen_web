# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin company lookup", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  it "offers a manual form and a URL form" do
    get new_admin_company_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include(I18n.t("admin.companies.tabs.manual"))
    expect(response.body).to include(I18n.t("admin.companies.tabs.url"))
  end

  it "queues a lookup from a job offer URL" do
    expect do
      post admin_company_lookups_path, params: {
        company_lookup: { source_url: "https://jobs.example/rails-dev" }
      }
    end.to change(CompanyLookup, :count).by(1).and have_enqueued_job(CompanyLookupJob)

    lookup = CompanyLookup.order(:created_at).last
    expect(response).to redirect_to(admin_company_lookup_path(lookup))
    expect(lookup.user).to eq(admin)
    expect(lookup.status).to eq("queued")
  end

  it "rejects an address that is not http" do
    post admin_company_lookups_path, params: { company_lookup: { source_url: "notaurl" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(I18n.t("admin.companies.tabs.url"))
  end
end
