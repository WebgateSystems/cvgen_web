# frozen_string_literal: true

module Jobseeker
  class ProfilesController < BaseController
    before_action :set_profile, only: %i[show edit update destroy]

    def index
      @profiles = current_user.cv_profiles.includes(:versions).order(:name)
    end

    def show
      @versions = @profile.versions.order(number: :desc)
    end

    def new
      @profile = current_user.cv_profiles.new
      @profile.versions.build
    end

    def create
      @profile = current_user.cv_profiles.new(profile_params)
      if @profile.save
        redirect_to jobseeker_profile_path(@profile), notice: t("jobseeker.profiles.created")
      else
        @profile.versions.build if @profile.versions.empty?
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @profile.update(profile_params.except(:versions_attributes))
        redirect_to jobseeker_profile_path(@profile), notice: t("jobseeker.profiles.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @profile.destroy
      redirect_to jobseeker_profiles_path, notice: t("jobseeker.profiles.deleted")
    end

    private

    def set_profile
      @profile = current_user.cv_profiles.find(params[:id])
    end

    def profile_params
      params.require(:cv_profile).permit(:name, versions_attributes: %i[file tag])
    end
  end
end
