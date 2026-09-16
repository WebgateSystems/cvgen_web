# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationEvent do
  it "requires a body for a message" do
    event = build(:application_event, kind: :message, body: "")
    expect(event).not_to be_valid
    expect(event.errors[:body]).to be_present
  end

  it "allows a status change without a body" do
    event = build(:application_event, :status_change)
    expect(event).to be_valid
  end
end
