# frozen_string_literal: true

require "openai"
require "base64"
require "timeout"

class ChatGpt
  IMAGE_TYPES = %w[image/jpeg image/jpg image/png image/gif image/webp].freeze
  IMAGE_EXT = %w[png jpg jpeg webp gif].freeze
  TIMEOUT = 90

  def initialize(prompt: nil, prompt_name: nil, file: nil, files: nil, model: "gpt-4o", temperature: 0.2, json: false, web_search: false, timeout: TIMEOUT)
    @prompt = prompt.presence || (prompt_name && Prompt.load(prompt_name))
    raise ArgumentError, "prompt or prompt_name is required" if @prompt.blank?
    raise ArgumentError, "Settings.chat_gpt_api_key is blank" if Settings.chat_gpt_api_key.blank?

    @attachments = Array.wrap(files).presence || Array.wrap(file)
    @model = model
    @temperature = temperature
    @json = json
    @web_search = web_search
    @timeout = timeout
    @client = OpenAI::Client.new(api_key: Settings.chat_gpt_api_key)
  end

  def call
    return search_call if @web_search

    params = {
      model: @model,
      messages: build_messages,
      temperature: @temperature
    }
    params[:response_format] = { type: "json_object" } if @json

    chat_completion = Timeout.timeout(@timeout) do
      @client.chat.completions.create(**params)
    end
    chat_completion.choices.first.message.content
  end

  def self.strip_fence(raw)
    raw.to_s.strip.sub(/\A```[a-z]*\s*/i, "").sub(/\s*```\s*\z/, "").strip
  end

  def self.parse_json(raw)
    text = strip_fence(raw)
    candidate = text[/\A\s*(\{.*\})\s*\z/m, 1] || text[/\{.*\}/m] || text
    JSON.parse(candidate)
  rescue JSON::ParserError
    raise ArgumentError, "ChatGPT response was not valid JSON"
  end

  def self.parse_markdown(raw)
    strip_fence(raw)
  end

  private

  def build_messages
    [ { role: "user", content: content_payload } ]
  end

  def content_payload
    return @prompt if @attachments.empty?

    [ text_payload, *@attachments.map { |io| attachment_payload(io) } ]
  end

  def text_payload
    { type: "text", text: @prompt }
  end

  def attachment_payload(io)
    filename = filename_for(io)
    mime = mime_for(io, filename)
    rewind(io)
    data = io.read
    rewind(io)

    if image?(filename, mime)
      {
        type: "image_url",
        image_url: {
          url: "data:#{image_mime(mime, filename)};base64,#{Base64.strict_encode64(data)}",
          detail: "high"
        }
      }
    else
      {
        type: "file",
        file: {
          filename: filename.presence || "document.pdf",
          file_data: "data:#{mime.presence || "application/octet-stream"};base64,#{Base64.strict_encode64(data)}"
        }
      }
    end
  end

  def image?(filename, mime)
    IMAGE_TYPES.include?(mime) || IMAGE_EXT.include?(File.extname(filename).delete(".").downcase)
  end

  def image_mime(mime, filename)
    return mime if IMAGE_TYPES.include?(mime)

    ext = File.extname(filename).delete(".").downcase
    ext = "jpeg" if ext == "jpg"
    "image/#{ext.presence || "jpeg"}"
  end

  def filename_for(io)
    io.try(:original_filename).presence ||
      (io.try(:path).present? && File.basename(io.path)) ||
      "upload.bin"
  end

  def mime_for(io, filename)
    rewind(io)
    Marcel::MimeType.for(io, name: filename).to_s
  ensure
    rewind(io)
  end

  def rewind(io)
    io.rewind if io.respond_to?(:rewind)
  end

  def search_call
    errors = []
    %w[web_search web_search_preview].each do |type|
      response = Timeout.timeout(@timeout) do
        @client.responses.create(
          model: @model,
          input: @prompt,
          tools: [ { type: type } ]
        )
      end
      return extract_output_text(response)
    rescue ArgumentError, Timeout::Error
      raise
    rescue StandardError => error
      errors << error
      Rails.logger.warn("[ChatGpt] web search #{type} failed: #{error.class}: #{error.message}")
    end
    raise errors.last
  end

  def extract_output_text(response)
    parts = Array(response.output).flat_map do |item|
      Array(item.respond_to?(:content) ? item.content : item[:content]).filter_map do |part|
        type = part.respond_to?(:type) ? part.type : part[:type]
        text = part.respond_to?(:text) ? part.text : part[:text]
        text if type.to_s == "output_text" && text.present?
      end
    end
    text = parts.join("\n").strip
    raise ArgumentError, "ChatGPT response was empty" if text.blank?

    text
  end
end
