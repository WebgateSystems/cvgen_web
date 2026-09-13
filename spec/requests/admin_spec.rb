# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin panel", type: :request do
  let(:admin) { create(:user, :admin) }

  it "blocks a jobseeker from admin" do
    sign_in create(:user, :jobseeker)
    get admin_root_path
    expect(response).to redirect_to(root_path)
  end

  it "shows the dashboard" do
    sign_in admin
    get admin_root_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include(I18n.t("admin.dashboard"))
  end

  it "lists and creates users" do
    sign_in admin
    get admin_users_path
    expect(response).to have_http_status(:success)

    get new_admin_user_path
    expect(response).to have_http_status(:success)

    expect do
      post admin_users_path, params: {
        user: {
          email: "new@example.com",
          password: "password123!",
          password_confirmation: "password123!",
          role: "jobseeker"
        }
      }
    end.to change(User, :count).by(1)

    expect(response).to redirect_to(admin_users_path)
  end

  it "rejects an invalid user" do
    sign_in admin
    post admin_users_path, params: { user: { email: "", password: "x", role: "jobseeker" } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "updates a user and ignores a blank password" do
    sign_in admin
    user = create(:user, :jobseeker, email: "keep@example.com")
    get edit_admin_user_path(user)
    expect(response).to have_http_status(:success)

    patch admin_user_path(user), params: {
      user: { email: "renamed@example.com", password: "", password_confirmation: "", role: "recruiter" }
    }
    expect(response).to redirect_to(admin_users_path)
    expect(user.reload).to be_recruiter
    expect(user.email).to eq("renamed@example.com")
  end

  it "rejects an invalid user update" do
    sign_in admin
    user = create(:user, :jobseeker)
    patch admin_user_path(user), params: { user: { email: "" } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "does not demote the last admin" do
    sign_in admin
    patch admin_user_path(admin), params: { user: { role: "jobseeker" } }
    expect(response).to redirect_to(admin_users_path)
    expect(admin.reload).to be_admin
  end

  it "does not let an admin delete themselves" do
    sign_in admin
    expect { delete admin_user_path(admin) }.not_to change(User, :count)
    expect(response).to redirect_to(admin_users_path)
  end

  it "deletes another admin when more than one remains" do
    sign_in admin
    other = create(:user, :admin)
    expect { delete admin_user_path(other) }.to change(User, :count).by(-1)
    expect(response).to redirect_to(admin_users_path)
  end

  it "does not delete the last remaining admin" do
    sign_in admin
    other = create(:user, :admin)
    allow(User).to receive(:admin).and_wrap_original do |original|
      relation = original.call
      allow(relation).to receive(:count).and_return(1)
      relation
    end

    expect { delete admin_user_path(other) }.not_to change(User, :count)
    expect(response).to redirect_to(admin_users_path)
  end

  it "demotes an admin when another admin remains" do
    sign_in admin
    other = create(:user, :admin)
    patch admin_user_path(other), params: { user: { role: "jobseeker" } }
    expect(other.reload).to be_jobseeker
  end

  it "creates, updates, and deletes a system theme" do
    sign_in admin
    get admin_themes_path
    expect(response).to have_http_status(:success)

    get new_admin_theme_path
    expect(response).to have_http_status(:success)

    expect do
      post admin_themes_path, params: {
        theme: { name: "Admin Blue", kind: "system", file: theme_upload }
      }
    end.to change(Theme, :count).by(1)

    theme = Theme.order(:created_at).last
    get edit_admin_theme_path(theme)
    expect(response).to have_http_status(:success)

    patch admin_theme_path(theme), params: { theme: { name: "Admin Blue 2" } }
    expect(theme.reload.name).to eq("Admin Blue 2")

    post admin_themes_path, params: { theme: { name: "", kind: "system" } }
    expect(response).to have_http_status(:unprocessable_entity)

    patch admin_theme_path(theme), params: { theme: { name: "" } }
    expect(response).to have_http_status(:unprocessable_entity)

    expect { delete admin_theme_path(theme) }.to change(Theme, :count).by(-1)
  end
end
