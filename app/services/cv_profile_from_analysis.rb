# frozen_string_literal: true

class CvProfileFromAnalysis
  class Error < StandardError; end
  class EmptyProfile < Error; end
  class MissingApiKey < Error; end
  class InvalidMarkdown < Error; end
  class Failed < Error; end

  def initialize(user_profile, name: nil)
    @user_profile = user_profile
    @user = user_profile.user
    @name = name.to_s.strip
  end

  def call
    record = @user.cv_profiles.new(name: unique_name)
    attach(record)
    record.save!
    record
  ensure
    cleanup
  end

  def attach(cv_profile)
    markdown = generate_markdown
    @tempfile = Tempfile.new([ "cv", ".md" ])
    @tempfile.write(markdown)
    @tempfile.flush
    @tempfile.rewind
    cv_profile.versions.build(file: @tempfile, tag: I18n.t("jobseeker.profiles.from_account_tag"))
    cv_profile
  end

  def cleanup
    @tempfile&.close
    @tempfile&.unlink
    @tempfile = nil
  end

  private

  def generate_markdown
    raise EmptyProfile unless @user_profile.cv_source_present?
    raise MissingApiKey if Settings.chat_gpt_api_key.blank?

    raw = ChatGpt.new(prompt: compose_prompt).call
    markdown = ChatGpt.parse_markdown(raw)
    raise InvalidMarkdown if markdown.blank? || !markdown.start_with?("---")

    CvgenMarkdown.normalize(markdown)
  rescue EmptyProfile, MissingApiKey, InvalidMarkdown
    raise
  rescue ArgumentError => error
    raise MissingApiKey if error.message.match?(/chat_gpt_api_key/)

    log_failure(error)
    raise Failed
  rescue StandardError => error
    log_failure(error)
    raise Failed
  end

  def compose_prompt
    [
      ChatGpt::Prompt.load("cv_profile"),
      "Career track name (write THIS profile, not every job in the JSON):\n#{track_name}",
      "Account about-me:\n#{about_payload.to_json}",
      "Structured CV analysis JSON (may mix several careers — keep only what belongs to this track):\n#{@user_profile.analysis_hash.to_json}"
    ].join("\n\n")
  end

  def about_payload
    {
      "display_name" => @user_profile.display_name.to_s,
      "email" => @user.email.to_s,
      "location" => @user_profile.location.to_s,
      "about" => @user_profile.about.to_s
    }
  end

  def track_name
    @name.presence ||
      @user_profile.analysis_hash["headline"].presence ||
      @user_profile.display_name.presence ||
      I18n.t("jobseeker.profiles.name_placeholder")
  end

  def unique_name
    base = track_name
    name = base
    suffix = 2
    while @user.cv_profiles.exists?(slug: name.to_s.parameterize)
      name = "#{base} #{suffix}"
      suffix += 1
    end
    name
  end

  def log_failure(error)
    Rails.logger.error("[CvProfileFromAnalysis] #{error.class}: #{error.message}")
    Rails.logger.error(error.backtrace&.first(12)&.join("\n"))
  end
end
