# frozen_string_literal: true

class CvAnalysisJob < ApplicationJob
  queue_as :default

  def perform(user_profile_id, text, file_paths, locale = I18n.default_locale.to_s)
    I18n.with_locale(locale) do
      profile = UserProfile.find(user_profile_id)
      uploads = Array(file_paths).map { |path| CvImportStore.open(path) }
      profile.progress!("reading")
      result = CvAnalysis.new(
        text: text,
        uploads: uploads,
        previous: profile.analysis_present? ? profile.analysis : nil,
        on_progress: ->(step) { profile.progress!(step) }
      ).call
      profile.progress!("saving")
      profile.apply_analysis!(result)
      profile.progress!("creating_profile")
      starter = create_starter_profile(profile)
      profile.starter_cv_profile = starter
      profile.mark_done!
    end
  rescue CvAnalysis::EmptyInput
    fail_profile(user_profile_id, I18n.t("jobseeker.account.import.empty"))
  rescue CvAnalysis::TooManyFiles
    fail_profile(user_profile_id, I18n.t("jobseeker.account.import.too_many"))
  rescue CvAnalysis::TooLarge => error
    fail_profile(user_profile_id, I18n.t("jobseeker.account.import.too_large", filename: error.filename))
  rescue CvAnalysis::UnsupportedFile => error
    fail_profile(user_profile_id, I18n.t("jobseeker.account.import.unsupported", filename: error.filename))
  rescue CvAnalysis::UnreadableFile => error
    fail_profile(user_profile_id, I18n.t("jobseeker.account.import.unreadable", filename: error.filename))
  rescue CvAnalysis::InvalidJson
    fail_profile(user_profile_id, I18n.t("jobseeker.account.import.invalid_json"))
  rescue CvAnalysis::MissingApiKey
    fail_profile(user_profile_id, I18n.t("jobseeker.account.import.missing_key"))
  rescue StandardError => error
    Rails.logger.warn("[CvAnalysisJob] #{error.class}: #{error.message}")
    fail_profile(user_profile_id, I18n.t("jobseeker.account.import.failed"))
  ensure
    Array(file_paths).each { |path| path.close if path.respond_to?(:close) }
    CvImportStore.cleanup(file_paths)
  end

  private

  def create_starter_profile(profile)
    CvProfileFromAnalysis.new(
      profile,
      name: profile.analysis_hash["headline"].presence || profile.display_name
    ).call
  rescue StandardError => error
    Rails.logger.warn("[CvProfileFromAnalysis] #{error.class}: #{error.message}")
    nil
  end

  def fail_profile(id, message)
    UserProfile.find_by(id: id)&.mark_failed!(message)
  end
end
