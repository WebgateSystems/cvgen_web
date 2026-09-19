# frozen_string_literal: true

class Identity < ApplicationRecord
  PROVIDERS = %w[google_oauth2 apple facebook linkedin].freeze

  belongs_to :user

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :uid, presence: true
  validates :uid, uniqueness: { scope: :provider }
end
