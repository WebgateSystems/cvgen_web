# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobApplication do
  it "defaults to reviewed and belongs to a user and company" do
    application = build(:job_application)
    expect(application).to be_valid
    expect(application).to be_reviewed
    expect(application.user).to be_present
    expect(application.company).to be_present
  end

  it "requires a position and company" do
    application = build(:job_application, position: "", company: nil)
    expect(application).not_to be_valid
    expect(application.errors[:position]).to be_present
    expect(application.errors[:company]).to be_present
  end

  it "rejects a bad link or email" do
    application = build(:job_application, link: "not-a-url", email: "nope")
    expect(application).not_to be_valid
    expect(application.errors[:link]).to be_present
    expect(application.errors[:email]).to be_present
  end

  it "treats blank optional enums as nil" do
    application = build(:job_application, work_mode: "", employment_type: "", contract_type: "", link: "", email: "")
    expect(application).to be_valid
    expect(application.work_mode).to be_nil
  end

  it "lists status keys for filters" do
    expect(described_class.status_options).to include("reviewed", "applied", "offer")
  end

  it "keeps a compact default column set for the index" do
    expect(described_class::INDEX_DEFAULT_COLUMNS).to eq(%w[position company posted_on status])
    expect(described_class::INDEX_COLUMNS).to include("expected_salary", "email")
  end

  it "orders recent applications by updated_at" do
    user = create(:user, :jobseeker)
    older = create(:job_application, user: user, company: create(:company, shortcut: "Older"))
    newer = create(:job_application, user: user, company: create(:company, shortcut: "Newer"))
    older.update_columns(updated_at: 2.days.ago)
    newer.update_columns(updated_at: 1.hour.ago)

    expect(described_class.recent).to eq([ newer, older ])
  end

  it "searches position and company from three characters" do
    user = create(:user, :jobseeker)
    ynd = create(:company, shortcut: "YND", official_name: "YND Sp. z o.o.")
    acme = create(:company, shortcut: "Acme", official_name: "Acme Platform")
    create(:job_application, user: user, position: "Regular Ruby Developer", company: ynd)
    create(:job_application, user: user, position: "Java Engineer", company: acme)

    short = described_class.search_text("YN").includes(:company).map { |row| row.company.shortcut }
    expect(short).to contain_exactly("YND", "Acme")
    expect(described_class.search_text("YND").includes(:company).map { |row| row.company.shortcut }).to eq(%w[YND])
    expect(described_class.search_text("Ruby").includes(:company).map { |row| row.company.shortcut }).to eq(%w[YND])
  end

  it "records a status event on create and on status change" do
    application = create(:job_application, status: :reviewed, status_note: "Found on JustJoin")
    expect(application.application_events.count).to eq(1)
    expect(application.application_events.first).to be_status_change
    expect(application.application_events.first.to_status).to eq("reviewed")
    expect(application.application_events.first.body).to eq("Found on JustJoin")

    application.update!(status: :rejected, dropout_reason: "ghosting", status_note: "No reply")
    event = application.application_events.order(:created_at).last
    expect(event).to be_status_change
    expect(event.from_status).to eq("reviewed")
    expect(event.to_status).to eq("rejected")
    expect(event.dropout_reason).to eq("ghosting")
  end

  it "requires a dropout reason when moving to rejected" do
    application = create(:job_application, status: :applied)
    application.status = :rejected
    expect(application).not_to be_valid
    expect(application.errors[:dropout_reason]).to be_present
  end
end
