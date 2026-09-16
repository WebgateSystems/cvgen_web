# frozen_string_literal: true

module Jobseeker
  class CompaniesController < BaseController
    def index
      @q = params[:q].to_s.strip
      @companies = Company.search_text(@q).includes(:company_ratings).order(:official_name)
    end

    def show
      @company = Company.includes(:company_ratings).find(params[:id])
      @rating = current_user.company_ratings.find_or_initialize_by(company: @company)
      @applications = current_user.job_applications.where(company: @company).recent
    end
  end
end
