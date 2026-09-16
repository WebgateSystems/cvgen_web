# frozen_string_literal: true

module Jobseeker
  class CompanyRatingsController < BaseController
    before_action :set_company

    def create
      upsert_rating
    end

    def update
      upsert_rating
    end

    private

    def set_company
      @company = Company.find(params[:company_id])
    end

    def upsert_rating
      @rating = current_user.company_ratings.find_or_initialize_by(company: @company)
      @rating.assign_attributes(rating_params)
      if @rating.save
        redirect_to jobseeker_company_path(@company), notice: t("jobseeker.companies.rating_saved")
      else
        @applications = current_user.job_applications.where(company: @company).recent
        @company = Company.includes(:company_ratings).find(@company.id)
        render "jobseeker/companies/show", status: :unprocessable_content
      end
    end

    def rating_params
      params.require(:company_rating).permit(
        :responsiveness, :seriousness, :human_process, :fairness, :comment
      )
    end
  end
end
