# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Jobseeker companies", type: :request do
  let(:jobseeker) { create(:user, :jobseeker) }
  let(:company) { create(:company, shortcut: "YND", official_name: "YND Sp. z o.o.", legal_id: "5252344078") }

  before { sign_in jobseeker }

  it "lists the shared catalog" do
    company
    create(:company, shortcut: "Acme", official_name: "Acme Platform")

    get jobseeker_companies_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("YND")
    expect(response.body).to include("Acme")
  end

  it "shows a company card and upserts a rating" do
    get jobseeker_company_path(company)
    expect(response).to have_http_status(:success)
    expect(response.body).to include("YND Sp. z o.o.")
    expect(response.body).to include("5252344078")

    expect do
      post jobseeker_company_rating_path(company), params: {
        company_rating: {
          responsiveness: 5,
          seriousness: 4,
          human_process: 3,
          fairness: 2,
          comment: "Slow but fair."
        }
      }
    end.to change(CompanyRating, :count).by(1)

    expect(response).to redirect_to(jobseeker_company_path(company))
    expect(company.company_ratings.find_by(user: jobseeker).overall).to eq(3.5)

    patch jobseeker_company_rating_path(company), params: {
      company_rating: { responsiveness: 5, seriousness: 5, human_process: 5, fairness: 5 }
    }
    expect(company.company_ratings.find_by(user: jobseeker).reload.overall).to eq(5.0)
  end
end
