# frozen_string_literal: true

module Jobseeker
  class ProfilesController < BaseController
    include ProfileEditor

    before_action :set_profile, only: %i[show edit update destroy]

    def index
      @profiles = current_user.cv_profiles.includes(:versions).order(:name)
    end

    def show
      load_profile_editor
    end

    def new
      @profile = current_user.cv_profiles.new
      @profile.versions.build
      assign_source_state
    end

    def create
      assign_source_state
      @profile = current_user.cv_profiles.new(name: params.dig(:cv_profile, :name))

      if account_source?
        queue_account_draft
      else
        @profile.assign_attributes(profile_params)
        save_or_render t("jobseeker.profiles.created")
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

    def assign_source_state
      @account_source_available = account_source_available?
      @source = params[:source].to_s
      @source = "upload" unless %w[upload account].include?(@source)
    end

    def account_source?
      @source == "account"
    end

    def account_source_available?
      current_user.user_profile&.cv_source_present?
    end

    def queue_account_draft
      unless @account_source_available
        @profile.errors.add(:base, t("jobseeker.profiles.from_account_empty"))
        return render_new
      end
      if @profile.name.blank?
        @profile.valid?
        return render_new
      end

      @profile.draft_status = "queued"
      if @profile.save
        CvProfileDraftJob.perform_later(@profile.id, I18n.locale.to_s)
        redirect_to jobseeker_profiles_path, notice: t("jobseeker.profiles.drafting_notice")
      else
        render_new
      end
    end

    def save_or_render(notice)
      if @profile.save
        redirect_to jobseeker_profile_path(@profile), notice: notice
      else
        render_new
      end
    end

    def render_new
      @profile.versions.build if @profile.versions.empty?
      render :new, status: :unprocessable_content
    end

    def profile_params
      params.require(:cv_profile).permit(:name, versions_attributes: %i[file tag])
    end
  end
end
