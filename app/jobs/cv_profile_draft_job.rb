# frozen_string_literal: true

class CvProfileDraftJob < ApplicationJob
  queue_as :default

  def perform(cv_profile_id, locale = I18n.default_locale.to_s)
    I18n.with_locale(locale) do
      record = CvProfile.find(cv_profile_id)
      record.mark_draft_running!
      @generator = CvProfileFromAnalysis.new(record.user.ensure_user_profile!, name: record.name)
      @generator.attach(record)
      record.save!
      record.mark_draft_done!
    end
  rescue CvProfileFromAnalysis::EmptyProfile
    fail_draft(cv_profile_id, I18n.t("jobseeker.profiles.from_account_empty"))
  rescue CvProfileFromAnalysis::MissingApiKey
    fail_draft(cv_profile_id, I18n.t("jobseeker.profiles.from_account_missing_key"))
  rescue CvProfileFromAnalysis::InvalidMarkdown
    fail_draft(cv_profile_id, I18n.t("jobseeker.profiles.from_account_invalid"))
  rescue StandardError => error
    Rails.logger.error("[CvProfileDraftJob] #{error.class}: #{error.message}")
    fail_draft(cv_profile_id, I18n.t("jobseeker.profiles.from_account_failed"))
  ensure
    @generator&.cleanup
  end

  private

  def fail_draft(id, message)
    CvProfile.find_by(id: id)&.mark_draft_failed!(message)
  end
end
