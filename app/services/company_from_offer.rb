# frozen_string_literal: true

class CompanyFromOffer
  class InvalidJson < StandardError; end
  class MissingApiKey < StandardError; end

  def initialize(lookup)
    @lookup = lookup
  end

  def call
    return if @lookup.status.in?(%w[found created])

    @lookup.update!(status: "running", step: "fetching", error: nil)
    pages = CompanyPage.collect(@lookup.source_url)
    @lookup.update!(step: "reading")
    payload = ask(pages)
    payload = with_register(pages, payload)
    @lookup.update!(payload: payload, step: "matching")
    finish(payload)
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
    Rails.logger.warn("[CompanyFromOffer] #{error.class}: #{error.message}")
    fail_lookup("failed", error.message)
  end

  private

  def ask(pages, web_search: true)
    raise MissingApiKey if Settings.chat_gpt_api_key.blank?

    parse_answer(request(pages, web_search: web_search))
  rescue InvalidJson, StandardError => error
    raise MissingApiKey if error.is_a?(MissingApiKey) || error.message.to_s.match?(/chat_gpt_api_key/)
    raise error if !web_search || @search_fallback

    Rails.logger.warn("[CompanyFromOffer] web search skipped: #{error.class}: #{error.message}")
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

  def with_register(pages, payload)
    return payload if Array(payload["identifiers"]).any?

    name = payload["official_name"].presence || payload["shortcut"]
    return payload if name.blank?

    scanned = []
    local = CompanyIdentifierScan.call(pages.drop(1).map(&:text))
    if local.any?
      payload["identifiers"] = merge_identifiers(payload["identifiers"], local)
      return payload
    end

    @lookup.update!(step: "registers")
    extra = CompanyRegistry.pages_for(name: name, city: payload["city"], country: payload["country"])
    return payload if extra.empty?

    scanned = CompanyIdentifierScan.call(extra.map(&:text))
    revised = ask(pages + extra, web_search: false)
    revised["identifiers"] = merge_identifiers(revised["identifiers"], scanned)
    revised
  rescue StandardError => error
    Rails.logger.warn("[CompanyFromOffer] register lookup skipped: #{error.class}: #{error.message}")
    payload["identifiers"] = merge_identifiers(payload["identifiers"], scanned)
    payload
  end

  def merge_identifiers(model_ids, scanned)
    scanned = Array(scanned)
    return Array(model_ids) if scanned.empty?

    taken = scanned.map { |item| item["kind"] }
    scanned + Array(model_ids).reject { |item| taken.include?(item["kind"]) }
  end

  def prompt_for(pages)
    source, *rest = pages
    registers, followed = rest.partition { |page| CompanyRegistry.registry?(page.final_url) }

    <<~TEXT
      #{ChatGpt::Prompt.load("company_lookup")}

      Allowed country codes: #{Company::COUNTRIES.join(", ")}

      #{page_block(source)}

      Company pages opened from links on that page. A job board usually hides the legal footer; these pages are the company site itself. Identifiers and the address printed here are verified:
      #{section_text(followed)}

      Public register pages opened for this company. Copy the NIP, REGON, and KRS that the page assigns to this company. Ignore other firms listed on the same page:
      #{section_text(registers)}
    TEXT
  end

  def section_text(pages)
    return "(none)" if pages.empty?

    pages.map { |page| page_block(page) }.join("\n\n")
  end

  def page_block(page)
    <<~TEXT
      URL: #{page.final_url}
      Title: #{page.title}
      Text:
      #{page.text.presence || "(no readable text)"}
    TEXT
  end

  def normalize(data)
    data = data.to_h.stringify_keys
    attrs = data.slice(*CompanyLookup::ATTRIBUTE_KEYS)
    attrs["kind"] = attrs["kind"].to_s.presence
    attrs["kind"] = nil unless Company::KINDS.include?(attrs["kind"])
    attrs["country"] = attrs["country"].to_s.upcase.presence
    attrs["country"] = nil unless Company::COUNTRIES.include?(attrs["country"])
    attrs["identifiers"] = normalize_identifiers(data["identifiers"])
    attrs["notes"] = data["notes"].to_s.strip.presence
    attrs.compact
  end

  def normalize_identifiers(list)
    Array(list).filter_map do |item|
      item = item.to_h.stringify_keys
      kind = item["kind"].to_s
      next unless CompanyIdentifier::KINDS.include?(kind)

      value = CompanyIdentifier.normalize(kind, item["value"])
      next if value.blank?

      { "kind" => kind, "value" => value }
    end.uniq
  end

  def finish(payload)
    existing = CompanyMatch.call(payload)
    if existing
      @lookup.update!(status: "found", company: existing, step: nil, error: nil)
      return
    end

    company = Company.new(payload.slice(*CompanyLookup::ATTRIBUTE_KEYS))
    company.identifiers_attributes = Array(payload["identifiers"])
    if company.save
      @lookup.update!(status: "created", company: company, step: nil, error: nil)
    else
      @lookup.update!(
        status: "incomplete",
        step: nil,
        error: company.errors.full_messages.to_sentence
      )
    end
  end

  def fail_lookup(key, detail = nil)
    message = I18n.t("admin.companies.lookup.errors.#{key}")
    detail = detail.to_s.squish.truncate(240)
    message = "#{message} #{detail}" if key == "failed" && detail.present?
    @lookup.update!(status: "failed", step: nil, error: message)
  end
end
