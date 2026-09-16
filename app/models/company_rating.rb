# frozen_string_literal: true

class CompanyRating < ApplicationRecord
  DIMENSIONS = %i[responsiveness seriousness human_process fairness].freeze
  SCORE_RANGE = 0..5

  belongs_to :company
  belongs_to :user

  before_validation :compute_overall

  validates :user_id, uniqueness: { scope: :company_id }
  validates(*DIMENSIONS, numericality: { only_integer: true, in: SCORE_RANGE })
  validates :comment, length: { maximum: 2000 }, allow_blank: true

  def formatted_overall
    format("%.1f", overall) if overall
  end

  private

  def compute_overall
    scores = DIMENSIONS.map { |dimension| public_send(dimension).to_i }
    mean = scores.sum.to_d / DIMENSIONS.size
    self.overall = mean.round(1)
  end
end
