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
    expect(response.body).to include(I18n.t("nav.edit"))
    expect(response.body).not_to include(I18n.t("admin.users.edit"))
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

  it "clones a system theme into a personal YAML editor" do
    system_theme = create(:theme, name: "Modern Stack")

    expect do
      post clone_jobseeker_theme_path(system_theme)
    end.to change { jobseeker.themes.personal.count }.by(1)

    theme = jobseeker.themes.personal.order(:created_at).last
    expect(response).to redirect_to(edit_jobseeker_theme_path(theme))
    follow_redirect!
    expect(response.body).to include("theme-yaml")
    expect(response.body).to include("\"family\":\"Roboto Condensed\"")
    expect(theme.reload.yaml_text).to include("fonts:")
  end

  it "updates a personal theme from yaml_text" do
    theme = create(:theme, :personal, user: jobseeker)
    yaml = ThemeYaml.patch(theme.yaml_text, heading: "Roboto Condensed", body: "Roboto Condensed")

    patch jobseeker_theme_path(theme), params: { theme: { name: "Roboto clone", yaml_text: yaml } }

    theme.reload
    expect(theme.name).to eq("Roboto clone")
    expect(theme.heading_font).to eq("Roboto Condensed")
    expect(theme.body_font).to eq("Roboto Condensed")
  end

  it "does not clone another user's personal theme" do
    other = create(:theme, :personal, user: create(:user, :jobseeker))
    post clone_jobseeker_theme_path(other)
    expect(response).to have_http_status(:not_found)
  end
end
