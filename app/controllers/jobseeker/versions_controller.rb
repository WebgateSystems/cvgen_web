# frozen_string_literal: true

module Jobseeker
  class VersionsController < BaseController
    before_action :set_profile

    def new
      @version = @profile.versions.new
    end

    def create
      @version = @profile.versions.new(version_params)
      if @version.save
        redirect_to jobseeker_profile_path(@profile), notice: t("jobseeker.versions.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @version = @profile.versions.find(params[:id])
      if @profile.versions.count <= 1
        redirect_to jobseeker_profile_path(@profile), alert: t("jobseeker.versions.cannot_delete_last")
      else
        @version.destroy
        redirect_to jobseeker_profile_path(@profile), notice: t("jobseeker.versions.deleted")
      end
    end

    private

    def set_profile
      @profile = current_user.cv_profiles.find(params[:profile_id])
    end

    def version_params
      params.require(:cv_profile_version).permit(:file, :tag)
    end
  end
end
