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
      @application.build_company(kind: :employer)
    end

    def show
      @application = current_user.job_applications.includes(:company, application_events: :user).find(params[:id])
      @event = @application.application_events.new
      render layout: false if turbo_frame_request?
    end

    def create
      @application = current_user.job_applications.new(application_params)
      if @application.save
        redirect_to jobseeker_applications_path, notice: t("jobseeker.applications.created")
      else
        @application.build_company(kind: :employer) if @application.company.blank?
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @application.build_company(kind: :employer) if @application.company.blank?
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
      scope = current_user.job_applications.includes(:company).recent.search_text(@q)
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
      permitted = params.require(:job_application).permit(
        :position, :company_id, :posted_on, :status,
        :expected_salary, :offered_salary,
        :work_mode, :employment_type, :contract_type,
        :link, :email, :dropout_reason, :status_note,
        company_attributes: %i[
          shortcut official_name kind country legal_id_kind legal_id
          street city postal_code
        ]
      )
      permitted[:company_id] = permitted[:company_id].presence if permitted.key?(:company_id)
      permitted.delete(:company_attributes) if permitted[:company_id].present?
      permitted
    end
  end
end
