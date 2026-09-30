# frozen_string_literal: true

module Jobseeker
  class ApplicationLookupsController < BaseController
    def create
      @lookup = current_user.application_lookups.new(lookup_params.merge(status: "queued"))
      if @lookup.save
        ApplicationLookupJob.perform_later(@lookup.id, I18n.locale.to_s)
        redirect_to jobseeker_application_lookup_path(@lookup)
      else
        @application = current_user.job_applications.new(status: :reviewed)
        @application.build_company(kind: :employer)
        @tab = "url"
        render "jobseeker/applications/new", status: :unprocessable_content
      end
    end

    def show
      @lookup = current_user.application_lookups.find(params[:id])
      @application = @lookup.to_application unless @lookup.pending? || @lookup.status == "failed"
    end

    private

    def lookup_params
      params.require(:application_lookup).permit(:source_url)
    end
  end
end
