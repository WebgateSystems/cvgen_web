# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  it "groups theme options by kind" do
    system_theme = create(:theme, name: "System Blue")
    personal = create(:theme, :personal, name: "My Theme")
    html = helper.theme_options_for_select([ system_theme, personal ], system_theme.id)

    expect(html).to include("System Blue")
    expect(html).to include("My Theme")
    expect(html).to include("selected")
    expect(html).to include(system_theme.slug)
  end

  it "maps application statuses to badge colors" do
    expect(helper.application_status_badge(:offer)).to eq("success")
    expect(helper.application_status_badge(:rejected)).to eq("danger")
    expect(helper.application_status_badge(:unknown)).to eq("secondary")
  end

  it "formats application fields for the show modal" do
    application = create(:job_application, expected_salary: "16 000 PLN", work_mode: :remote, link: "https://example.com")
    expect(helper.application_field_value(application, "expected_salary")).to eq("16 000 PLN")
    expect(helper.application_field_value(application, "work_mode")).to eq(I18n.t("jobseeker.applications.work_modes.remote"))
    expect(helper.application_field_value(application, "link")).to include("https://example.com")
    expect(helper.application_field_value(build(:job_application, email: nil), "email")).to eq("—")
  end
end
