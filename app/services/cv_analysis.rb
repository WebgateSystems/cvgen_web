# frozen_string_literal: true

class CvAnalysis
  class Error < StandardError; end
  class EmptyInput < Error; end
  class TooManyFiles < Error; end
  class InvalidJson < Error; end
  class MissingApiKey < Error; end
  class Failed < Error; end

  class UnsupportedFile < Error
    attr_reader :filename

    def initialize(filename)
      @filename = filename
      super
    end
  end

  class TooLarge < Error
    attr_reader :filename

    def initialize(filename)
      @filename = filename
      super
    end
  end

  class UnreadableFile < Error
    attr_reader :filename

    def initialize(filename)
      @filename = filename
      super
    end
  end

  MAX_FILES = 5
  MAX_PROMPT_CHARS = 80_000

  def initialize(text: "", uploads: [], previous: nil, on_progress: nil)
    @text = text.to_s
    @uploads = Array(uploads).flatten.select { |file| present_upload?(file) }
    @previous = previous
    @on_progress = on_progress
  end

  def call
    raise EmptyInput if @text.blank? && @uploads.empty?
    raise TooManyFiles if @uploads.size > MAX_FILES
    raise MissingApiKey if Settings.chat_gpt_api_key.blank?

    documents = @uploads.map { |upload| CvDocument.new(upload) }
    if (unreadable = unreadable_pdf(documents))
      raise UnreadableFile.new(unreadable.filename)
    end

    ask_model(documents)
  end

  private

  def ask_model(documents)
    @on_progress&.call("analyzing")
    raw = ChatGpt.new(
      prompt: compose_prompt(documents),
      files: documents.select(&:attach_to_model?).map(&:io_for_model),
      json: true
    ).call

    UserProfile::Analysis.normalize(ChatGpt.parse_json(raw))
  rescue ArgumentError => error
    raise InvalidJson if error.message.match?(/JSON/)
    raise MissingApiKey if error.message.match?(/chat_gpt_api_key/)

    log_failure(error)
    raise Failed
  rescue StandardError => error
    log_failure(error)
    raise Failed
  end

  def present_upload?(file)
    return false if file.blank?
    return file.size.to_i.positive? if file.respond_to?(:size)

    true
  end

  def compose_prompt(documents)
    parts = [ ChatGpt::Prompt.load("cv_analysis"), merge_instructions ]
    parts << previous_block if previous_present?
    parts << "Pasted CV text:\n#{truncate(@text)}" if @text.present?
    parts.concat(documents.filter_map { |document| document_block(document) })
    parts.join("\n\n")
  end

  def merge_instructions
    <<~TEXT.strip
      Several sources may be given (pasted text, extracted file text, attached images, and an optional previous JSON draft).
      Merge them into ONE JSON object. Union skills, phones (by number), and links (by URL). Union languages by name (keep the more specific level). Deduplicate experience by company + role (keep richer highlights and the wider date range).
      Never invent employers, degrees, language levels, or contact details. Prefer specific dates. Do not empty a field that the previous draft already filled unless the new sources clearly replace it.
      Always keep contact from the CVs: email, phones, location, LinkedIn, GitHub, and other listed URLs.
    TEXT
  end

  def previous_block
    "Previous analysis JSON (draft to enrich, not to wipe):\n#{@previous.to_json}"
  end

  def previous_present?
    hash = UserProfile::Analysis.normalize(@previous)
    hash.fetch_values("person_name", "headline", "summary").any?(&:present?) ||
      hash.dig("contact", "email").present? ||
      Array(hash.dig("contact", "phones")).any? ||
      Array(hash.dig("contact", "links")).any? ||
      hash.fetch_values("skills", "languages", "experience", "education", "strengths", "gaps").any?(&:present?)
  end

  def document_block(document)
    if document.extracted_text.present?
      "Extracted text from #{document.filename}:\n#{truncate(document.extracted_text)}"
    elsif document.image?
      "An image of a CV is attached (#{document.filename}). Read the image."
    end
  end

  def unreadable_pdf(documents)
    documents.find { |document| document.pdf? && document.extracted_text.blank? }
  end

  def log_failure(error)
    Rails.logger.error("[CvAnalysis] #{error.class}: #{error.message}")
    Rails.logger.error(error.backtrace&.first(12)&.join("\n"))
  end

  def truncate(text)
    text.to_s.truncate(MAX_PROMPT_CHARS)
  end
end
