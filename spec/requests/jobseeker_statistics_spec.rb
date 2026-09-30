# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Jobseeker statistics", type: :request do
  let(:jobseeker) { create(:user, :jobseeker) }

  before { sign_in jobseeker }

  it "charts offers sent and replies in the selected period" do
    application = create(:job_application, user: jobseeker, status: :reviewed)
    application.application_events.create!(user: jobseeker, kind: :status_change, to_status: "applied")
    application.application_events.create!(user: jobseeker, kind: :status_change, to_status: "interview")

    get jobseeker_statistics_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include(I18n.t("jobseeker.statistics.title"))
    expect(response.body).to include(I18n.t("jobseeker.statistics.sent"))
    expect(response.body).to match(/#{Regexp.escape(I18n.t("jobseeker.statistics.sent"))}<\/span>\s*<strong>1<\/strong>/)
    expect(response.body).to match(/#{Regexp.escape(I18n.t("jobseeker.statistics.replies"))}<\/span>\s*<strong>1<\/strong>/)
    expect(response.body).to match(/#{Regexp.escape(I18n.t("jobseeker.statistics.offers"))}<\/span>\s*<strong>0<\/strong>/)
  end
end
