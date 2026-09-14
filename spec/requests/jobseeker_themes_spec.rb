# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Jobseeker themes", type: :request do
  let(:jobseeker) { create(:user, :jobseeker) }

  before { sign_in jobseeker }

  it "lists personal and system themes" do
    create(:theme, name: "System Blue")
    create(:theme, :personal, user: jobseeker, name: "My Theme")

    get jobseeker_themes_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("System Blue")
    expect(response.body).to include("My Theme")
  end

  it "creates, updates, and deletes a personal theme" do
    get new_jobseeker_theme_path
    expect(response).to have_http_status(:success)

    expect do
      post jobseeker_themes_path, params: { theme: { name: "Mine", file: theme_upload } }
    end.to change { jobseeker.themes.count }.by(1)

    theme = Theme.personal.where(user: jobseeker).order(:created_at).last
    get edit_jobseeker_theme_path(theme)
    expect(response).to have_http_status(:success)

    patch jobseeker_theme_path(theme), params: { theme: { name: "Mine 2" } }
    expect(theme.reload.name).to eq("Mine 2")

    expect { delete jobseeker_theme_path(theme) }.to change { jobseeker.themes.count }.by(-1)
  end

  it "rejects an invalid personal theme" do
    post jobseeker_themes_path, params: { theme: { name: "" } }
    expect(response).to have_http_status(:unprocessable_content)

    theme = create(:theme, :personal, user: jobseeker)
    patch jobseeker_theme_path(theme), params: { theme: { name: "" } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "does not let a jobseeker edit a system theme" do
    theme = create(:theme)
    get edit_jobseeker_theme_path(theme)
    expect(response).to have_http_status(:not_found)
  end
end
