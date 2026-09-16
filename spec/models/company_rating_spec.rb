# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyRating do
  it "stores overall as the mean of four dimensions" do
    rating = build(:company_rating, responsiveness: 5, seriousness: 4, human_process: 3, fairness: 2)
    expect(rating).to be_valid
    expect(rating.overall).to eq(3.5)
    expect(rating.formatted_overall).to eq("3.5")
  end

  it "allows a zero score meaning the dimension does not exist" do
    rating = build(:company_rating, responsiveness: 0, seriousness: 0, human_process: 0, fairness: 0)
    expect(rating).to be_valid
    expect(rating.overall).to eq(0.0)
  end

  it "rejects a score outside 0-5" do
    rating = build(:company_rating, fairness: 6)
    expect(rating).not_to be_valid
    expect(rating.errors[:fairness]).to be_present
  end

  it "allows only one rating per user and company" do
    rating = create(:company_rating)
    duplicate = build(:company_rating, company: rating.company, user: rating.user)
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to be_present
  end
end
