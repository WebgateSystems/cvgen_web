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
      @lookup = current_user.application_lookups.new
    end

    def show
      @application = current_user.job_applications.includes(:company, application_events: :user).find(params[:id])
      @event = @application.application_events.new
      render layout: false if turbo_frame_request?
    end

    def create
      @application = current_user.job_applications.new(application_params)
      if persist_application(@application)
        redirect_to jobseeker_applications_path, notice: t("jobseeker.applications.created")
      else
        @application.build_company(kind: :employer) if @application.company.blank?
        @lookup = current_user.application_lookups.new
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @application.build_company(kind: :employer) if @application.company.blank?
    end

    def update
      @application.assign_attributes(application_params)
      if persist_application(@application)
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

    def section_params(value)
      list = value.respond_to?(:values) ? value.values : Array(value)
      list.map { |item| item.respond_to?(:to_h) ? item.to_h : item }
    end

    def capture_catalog_company(permitted)
      attrs = permitted[:company_attributes]
      return if attrs.blank?

      nested_id = attrs[:id].presence
      selected = permitted[:company_id].presence
      if nested_id.present? && (selected.blank? || selected == nested_id.to_s)
        permitted[:company_id] = nested_id
        permitted.delete(:company_attributes)
        @catalog_company_id = nested_id.to_s
        @catalog_company_attrs = attrs.except(:id)
      elsif selected.present?
        permitted.delete(:company_attributes)
      end
    end

    def persist_application(application)
      saved = false
      JobApplication.transaction do
        company_ok = catalog_company_id.blank? || update_catalog_company(application)
        application.validate unless company_ok
        saved = company_ok && application.save
        raise ActiveRecord::Rollback unless saved
      end
      saved
    end

    def update_catalog_company(application)
      company = application.company if application.company&.id.to_s == catalog_company_id
      company ||= Company.includes(:identifiers).find_by(id: catalog_company_id)
      return true unless company

      company.assign_attributes(catalog_company_attrs)
      application.company = company
      return true if company.save

      company.errors.full_messages.each { |message| application.errors.add(:base, message) }
      false
    end

    def catalog_company_id
      @catalog_company_id
    end

    def catalog_company_attrs
      @catalog_company_attrs
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
        :link, :email, :dropout_reason, :status_note, :sections_present,
        sections: %i[key title body],
        company_attributes: [
          :id, :shortcut, :official_name, :kind, :country, :street, :city, :postal_code,
          { identifiers_attributes: %i[id kind value _destroy] }
        ]
      )
      permitted[:company_id] = permitted[:company_id].presence if permitted.key?(:company_id)
      capture_catalog_company(permitted)
      if permitted.key?(:sections_present)
        permitted.delete(:sections_present)
        permitted[:sections] = section_params(permitted[:sections])
      end
      permitted
    end
  end
end
