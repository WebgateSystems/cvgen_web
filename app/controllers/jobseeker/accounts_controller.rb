# frozen_string_literal: true

module Jobseeker
  class AccountsController < BaseController
    def show
      @profile = current_user.ensure_user_profile!
    end

    def update
      @profile = current_user.ensure_user_profile!
      if @profile.update(profile_params)
        redirect_to jobseeker_account_path, notice: t("jobseeker.account.updated")
      else
        render :show, status: :unprocessable_content
      end
    end

    def analyze
      @profile = current_user.ensure_user_profile!
      @source_text = params[:source_text]
      payload = CvAnalysis.new(
        text: @source_text,
        uploads: Array(params[:cv_files]),
        previous: @profile.analysis_present? ? @profile.analysis : nil
      ).call
      @profile.apply_analysis!(payload)
      redirect_to jobseeker_account_path, notice: t("jobseeker.account.import.success")
    rescue CvAnalysis::EmptyInput
      import_failed t("jobseeker.account.import.empty")
    rescue CvAnalysis::TooManyFiles
      import_failed t("jobseeker.account.import.too_many")
    rescue CvAnalysis::TooLarge => error
      import_failed t("jobseeker.account.import.too_large", filename: error.filename)
    rescue CvAnalysis::UnsupportedFile => error
      import_failed t("jobseeker.account.import.unsupported", filename: error.filename)
    rescue CvAnalysis::UnreadableFile => error
      import_failed t("jobseeker.account.import.unreadable", filename: error.filename)
    rescue CvAnalysis::InvalidJson
      import_failed t("jobseeker.account.import.invalid_json")
    rescue CvAnalysis::MissingApiKey
      import_failed t("jobseeker.account.import.missing_key")
    rescue CvAnalysis::Error
      import_failed t("jobseeker.account.import.failed")
    end

    private

    def import_failed(message)
      @profile ||= current_user.ensure_user_profile!
      @source_text = params[:source_text]
      flash.now[:alert] = message
      render :show, status: :unprocessable_content
    end

    def profile_params
      permitted = params.require(:user_profile).permit(
        :display_name, :about, :location, :avatar, :remove_avatar,
        analysis: [
          :person_name, :headline, :summary,
          :skills_text, :languages_text, :strengths_text, :gaps_text,
          { languages: %i[name level] },
          { contact: [ :email, :location, { phones: %i[label number] }, { links: %i[label url] } ] },
          { experience: %i[company role from to highlights_text] },
          { education: %i[school degree year] }
        ]
      )
      permitted[:analysis] = UserProfile::Analysis.from_form(permitted[:analysis]) if permitted.key?(:analysis)
      permitted
    end
  end
end
