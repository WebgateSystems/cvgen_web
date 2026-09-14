# frozen_string_literal: true

module Jobseeker
  class ApplicationsController < BaseController
    before_action :set_application, only: %i[show edit update destroy]

    def index
      @q = params[:q].to_s.strip
      @active_status = params[:status].to_s.presence
      @page = infinite? ? [ params[:page].to_i, 1 ].max : 1
      @counts_by_status = current_user.job_applications.group(:status).count

      scope = filtered_applications
      @filtered_count = scope.count
      @applications = scope.offset((@page - 1) * JobApplication::PAGE_SIZE).limit(JobApplication::PAGE_SIZE)
      @has_more = ((@page - 1) * JobApplication::PAGE_SIZE) + @applications.size < @filtered_count

      return unless infinite?

      response.set_header("X-Has-More", @has_more ? "1" : "0")
      response.set_header("X-Page", @page.to_s)
      render partial: "rows", locals: { applications: @applications }, layout: false
    end

    def new
      @application = current_user.job_applications.new(status: :reviewed)
    end

    def show
      render layout: false if turbo_frame_request?
    end

    def create
      @application = current_user.job_applications.new(application_params)
      if @application.save
        redirect_to jobseeker_applications_path, notice: t("jobseeker.applications.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @application.update(application_params)
        redirect_to jobseeker_applications_path, notice: t("jobseeker.applications.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @application.destroy
      redirect_to jobseeker_applications_path, notice: t("jobseeker.applications.deleted")
    end

    private

    def set_application
      @application = current_user.job_applications.find(params[:id])
    end

    def filtered_applications
      scope = current_user.job_applications.recent.search_text(@q)
      return scope unless JobApplication.statuses.key?(@active_status.to_s)

      scope.where(status: @active_status)
    end

    def infinite?
      params[:rows] == "1"
    end

    def application_index_params
      { status: @active_status, q: (@q if @q.length >= 3) }.compact
    end
    helper_method :application_index_params

    def application_params
      params.require(:job_application).permit(
        :position, :company, :posted_on, :status,
        :expected_salary, :offered_salary,
        :work_mode, :employment_type, :contract_type,
        :link, :email
      )
    end
  end
end
