# frozen_string_literal: true

class ApplicationFromOffer
  class InvalidJson < StandardError; end
  class MissingApiKey < StandardError; end

  def initialize(lookup)
    @lookup = lookup
  end

  def call
    return if @lookup.status == "ready"

    @lookup.update!(status: "running", step: "fetching", error: nil)
    pages = CompanyPage.collect(@lookup.source_url)
    @lookup.update!(step: "reading")
    payload = ask(pages)
    payload["link"] ||= @lookup.source_url
    @lookup.update!(step: "company")
    attach_company(payload)
    @lookup.update!(payload: payload, status: "ready", company_id: payload["company_id"], step: nil, error: nil)
  rescue CompanyPage::InvalidUrl
    fail_lookup("invalid_url")
  rescue CompanyPage::BlockedHost
    fail_lookup("blocked")
  rescue CompanyPage::FetchFailed, CompanyPage::Error
    fail_lookup("fetch")
  rescue InvalidJson
    fail_lookup("invalid_json")
  rescue MissingApiKey
    fail_lookup("missing_key")
  rescue StandardError => error
    Rails.logger.warn("[ApplicationFromOffer] #{error.class}: #{error.message}")
    fail_lookup("failed", error.message)
  end

  private

  def ask(pages)
    raise MissingApiKey if Settings.chat_gpt_api_key.blank?

    parse_answer(request(pages, web_search: true))
  rescue InvalidJson, StandardError => error
    raise MissingApiKey if error.is_a?(MissingApiKey) || error.message.to_s.match?(/chat_gpt_api_key/)
    raise error if @search_fallback

    Rails.logger.warn("[ApplicationFromOffer] web search skipped: #{error.class}: #{error.message}")
    @search_fallback = true
    parse_answer(request(pages, web_search: false))
  end

  def request(pages, web_search:)
    ChatGpt.new(
      prompt: prompt_for(pages),
      temperature: 0.1,
      web_search: web_search,
      timeout: 180
    ).call
  end

  def parse_answer(raw)
    normalize(ChatGpt.parse_json(raw))
  rescue ArgumentError => error
    raise MissingApiKey if error.message.match?(/chat_gpt_api_key/)
    raise InvalidJson if error.message.match?(/JSON|empty/)

    raise
  end

  def prompt_for(pages)
    blocks = pages.map do |page|
      <<~TEXT
        URL: #{page.final_url}
        Title: #{page.title}
        Text:
        #{page.text.presence || "(no readable text)"}
      TEXT
    end

    <<~TEXT
      #{ChatGpt::Prompt.load("application_lookup")}

      #{blocks.join("\n")}
    TEXT
  end

  def normalize(data)
    data = data.to_h.stringify_keys
    attrs = data.slice(*ApplicationLookup::APPLICATION_KEYS)
    attrs["work_mode"] = enum_or_nil(attrs["work_mode"], JobApplication::WORK_MODES)
    attrs["employment_type"] = enum_or_nil(attrs["employment_type"], JobApplication::EMPLOYMENT_TYPES)
    attrs["contract_type"] = enum_or_nil(attrs["contract_type"], JobApplication::CONTRACT_TYPES)
    attrs["posted_on"] = attrs["posted_on"].to_s.presence
    attrs["sections"] = normalize_sections(data["sections"])
    attrs["company"] = normalize_company(data["company"])
    attrs.compact
  end

  def enum_or_nil(value, allowed)
    value.to_s.presence.then { |item| allowed.include?(item) ? item : nil }
  end

  def normalize_sections(list)
    Array(list).filter_map { |item| JobApplication.clean_section(item) }.first(12)
  end

  def normalize_company(data)
    data = data.to_h.stringify_keys
    attrs = data.slice(*CompanyLookup::ATTRIBUTE_KEYS)
    attrs["kind"] = attrs["kind"].to_s.presence
    attrs["kind"] = nil unless Company::KINDS.include?(attrs["kind"])
    attrs["country"] = attrs["country"].to_s.upcase.presence
    attrs["country"] = nil unless Company::COUNTRIES.include?(attrs["country"])
    attrs["identifiers"] = Array(data["identifiers"]).filter_map do |item|
      item = item.to_h.stringify_keys
      kind = item["kind"].to_s
      next unless CompanyIdentifier::KINDS.include?(kind)

      value = CompanyIdentifier.normalize(kind, item["value"])
      next if value.blank?

      { "kind" => kind, "value" => value }
    end.uniq
    attrs.compact
  end

  def attach_company(payload)
    existing = CompanyMatch.call(payload["company"] || {})
    if existing
      payload["company_id"] = existing.id
      @lookup.update!(company: existing)
      return
    end

    company_lookup = CompanyLookup.create!(
      user: @lookup.user,
      source_url: @lookup.source_url,
      status: "queued"
    )
    CompanyFromOffer.new(company_lookup).call
    company_lookup.reload
    payload["company_id"] = company_lookup.company_id if company_lookup.company_id.present?
  end

  def fail_lookup(key, detail = nil)
    message = I18n.t("jobseeker.applications.lookup.errors.#{key}")
    detail = detail.to_s.squish.truncate(240)
    message = "#{message} #{detail}" if key == "failed" && detail.present?
    @lookup.update!(status: "failed", error: message)
  end
end
