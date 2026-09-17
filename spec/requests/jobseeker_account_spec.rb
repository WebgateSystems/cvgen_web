# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Jobseeker account", type: :request do
  it "opens the profile page and creates a user_profiles row" do
    user = create(:user, :jobseeker)
    sign_in user

    expect { get jobseeker_account_path }.to change(UserProfile, :count).by(1)
    expect(response).to have_http_status(:success)
    expect(response.body).to include(I18n.t("jobseeker.account.title"))
    expect(response.body).to include(I18n.t("jobseeker.account.about_legend"))
    expect(response.body).to include(I18n.t("jobseeker.account.import.legend"))
    expect(response.body).not_to include(I18n.t("jobseeker.account.analysis_legend"))
    expect(response.body).not_to include(I18n.t("jobseeker.account.experience"))
    expect(response.body).not_to include(I18n.t("jobseeker.account.education"))
    expect(response.body).not_to include(I18n.t("jobseeker.account.skills"))
    expect(response.body).not_to include(I18n.t("jobseeker.account.languages"))
  end

  it "saves about-me fields and editable analysis JSON" do
    user = create(:user, :jobseeker)
    sign_in user
    get jobseeker_account_path

    patch jobseeker_account_path, params: {
      user_profile: {
        display_name: "Ada",
        location: "London",
        about: "Notes on the engine.",
        analysis: {
          person_name: "Ada Lovelace",
          headline: "Mathematician",
          summary: "Analytical Engine",
          skills_text: "Mathematics\nNotes",
          languages: {
            "0" => { name: "English", level: "C1" }
          },
          strengths_text: "Abstraction",
          gaps_text: "",
          experience: {
            "0" => { company: "Analytical Engine", role: "Collaborator", from: "1842", to: "1843", highlights_text: "Bernoulli" },
            "1" => { company: "", role: "", from: "", to: "", highlights_text: "" }
          },
          education: {
            "0" => { school: "Private tutors", degree: "Mathematics", year: "1834" }
          }
        }
      }
    }

    expect(response).to redirect_to(jobseeker_account_path)
    follow_redirect!
    expect(response.body).to include(I18n.t("jobseeker.account.updated"))

    profile = user.reload.user_profile
    expect(profile.display_name).to eq("Ada")
    expect(profile.location).to eq("London")
    expect(profile.analysis["skills"]).to eq(%w[Mathematics Notes])
    expect(profile.analysis["languages"]).to eq([ { "name" => "English", "level" => "C1" } ])
    expect(profile.analysis["experience"].size).to eq(1)
    expect(profile.analysis["education"].sole["school"]).to eq("Private tutors")
  end

  it "shows filled analysis including language levels" do
    user = create(:user, :jobseeker)
    create(:user_profile, :analyzed, user: user)
    sign_in user

    get jobseeker_account_path

    expect(response.body).to include(I18n.t("jobseeker.account.analysis_legend"))
    expect(response.body).to include(I18n.t("jobseeker.account.languages"))
    expect(response.body).to include(I18n.t("jobseeker.account.language_level"))
    expect(response.body).to include("C1")
    expect(response.body).to include(I18n.t("jobseeker.account.experience"))
    expect(response.body).to include("Analytical Engine")
  end

  it "shows the avatar menu on the studio dashboard" do
    sign_in create(:user, :jobseeker, email: "ada@example.com")
    get jobseeker_root_path

    expect(response.body).to include(I18n.t("nav.account"))
    expect(response.body).to include("ada@example.com")
    expect(response.body).to include("user-menu-toggle")
  end

  it "blocks a recruiter from the account page" do
    sign_in create(:user, :recruiter)
    get jobseeker_account_path
    expect(response).to redirect_to(root_path)
  end

  it "fills analysis from pasted text via ChatGPT" do
    user = create(:user, :jobseeker)
    sign_in user
    get jobseeker_account_path

    payload = {
      "person_name" => "Ada Lovelace",
      "headline" => "Mathematician",
      "summary" => "Analytical Engine",
      "skills" => [ "Mathematics", "Notes" ],
      "languages" => [],
      "experience" => [],
      "education" => [],
      "strengths" => [],
      "gaps" => []
    }
    allow(ChatGpt).to receive(:new).and_return(instance_double(ChatGpt, call: payload.to_json))

    post analyze_jobseeker_account_path, params: { source_text: "Ada Lovelace, first programmer." }

    expect(response).to redirect_to(jobseeker_account_path)
    follow_redirect!
    expect(response.body).to include(I18n.t("jobseeker.account.import.success"))
    expect(user.reload.user_profile.analysis["person_name"]).to eq("Ada Lovelace")
    expect(user.user_profile.analysis["skills"]).to eq(%w[Mathematics Notes])
  end

  it "extracts text from a temporary txt upload" do
    user = create(:user, :jobseeker)
    sign_in user
    allow(ChatGpt).to receive(:new).and_return(
      instance_double(ChatGpt, call: { "person_name" => "Ada", "skills" => [ "Ruby" ] }.to_json)
    )

    post analyze_jobseeker_account_path, params: {
      cv_files: [ cv_text_upload("Ada Lovelace Ruby on Rails") ]
    }

    expect(response).to redirect_to(jobseeker_account_path)
    expect(ChatGpt).to have_received(:new).with(
      hash_including(prompt: a_string_including("Ada Lovelace Ruby on Rails"))
    )
    expect(user.reload.user_profile.analysis["person_name"]).to eq("Ada")
  end

  it "extracts text from a temporary PDF upload" do
    user = create(:user, :jobseeker)
    sign_in user
    page = instance_double(PDF::Reader::Page, text: "Ada Lovelace Ruby on Rails")
    allow(PDF::Reader).to receive(:new).and_return(instance_double(PDF::Reader, pages: [ page ]))
    allow(ChatGpt).to receive(:new).and_return(
      instance_double(ChatGpt, call: { "person_name" => "Ada", "skills" => [ "Ruby" ] }.to_json)
    )

    post analyze_jobseeker_account_path, params: {
      cv_files: [ cv_text_upload("%PDF-1.4 body", name: "cv.pdf") ]
    }

    expect(response).to redirect_to(jobseeker_account_path)
    expect(ChatGpt).to have_received(:new).with(
      hash_including(prompt: a_string_including("Ada Lovelace Ruby on Rails"), files: [])
    )
    expect(user.reload.user_profile.analysis["person_name"]).to eq("Ada")
  end

  it "explains when a PDF has no extractable text" do
    sign_in create(:user, :jobseeker)

    post analyze_jobseeker_account_path, params: {
      cv_files: [ cv_text_upload("%PDF-1.4", name: "scan.pdf") ]
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("scan.pdf")
    expect(response.body).to include(I18n.t("jobseeker.account.import.unreadable", filename: "scan.pdf"))
  end

  it "keeps pasted text when there is nothing to analyze" do
    sign_in create(:user, :jobseeker)
    post analyze_jobseeker_account_path, params: { source_text: "" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(I18n.t("jobseeker.account.import.empty"))
  end

  it "rejects an unsupported upload type" do
    sign_in create(:user, :jobseeker)
    post analyze_jobseeker_account_path, params: {
      cv_files: [ cv_text_upload("MZ", name: "notes.exe") ]
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("notes.exe")
  end
end
