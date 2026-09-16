# frozen_string_literal: true

module Jobseeker
  class ApplicationEventsController < BaseController
    def create
      @application = current_user.job_applications.find(params[:application_id])
      @event = @application.application_events.new(event_params.merge(user: current_user, kind: :message))
      if @event.save
        redirect_to jobseeker_application_path(@application), notice: t("jobseeker.applications.event_created")
      else
        @application = current_user.job_applications.includes(:company, application_events: :user).find(@application.id)
        render "jobseeker/applications/show", status: :unprocessable_content, layout: !turbo_frame_request?
      end
    end

    private

    def event_params
      params.require(:application_event).permit(:body)
    end
  end
end
