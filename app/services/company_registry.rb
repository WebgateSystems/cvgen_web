# frozen_string_literal: true

require "cgi"

class CompanyRegistry
  SEARCH_URL = "https://html.duckduckgo.com/html/"
  MAX_PAGES = 3
  REGISTRY_HOST = /
    krs-online|krs-pobierz|rejestr\.io|ceidg\.gov|stat\.gov|dane-firm|
    aleo\.com|panoramafirm|biznes\.gov|imsig\.pl|northdata|opencorporates|
    company-information\.service\.gov|find-and-update\.company-information
  /ix

  def self.pages_for(name:, city: nil, country: nil)
    new(name: name, city: city, country: country).pages
  end

  def self.registry?(url)
    CompanyPage.registrable_host(url).match?(REGISTRY_HOST)
  end

  def self.targets_from(links)
    decoded = Array(links).filter_map { |link| unwrap(link) }.uniq
    decoded = decoded.select { |url| useful?(url) }
    decoded = decoded.uniq { |url| CompanyPage.registrable_host(url) }
    decoded.sort_by { |url| registry?(url) ? 0 : 1 }.first(MAX_PAGES)
  end

  def self.unwrap(link)
    uri = URI.parse(link.to_s)
    return if uri.host.blank?

    host = uri.host.downcase.sub(/\Awww\./, "")
    if host == "duckduckgo.com" || host.end_with?(".duckduckgo.com")
      target = URI.decode_www_form(uri.query.to_s).assoc("uddg")&.last
      return target if target.to_s.start_with?("http")

      return
    end

    link if uri.is_a?(URI::HTTP)
  rescue URI::InvalidURIError
    nil
  end

  def self.useful?(url)
    host = CompanyPage.registrable_host(url)
    return false if host.blank? || CompanyPage.skipped_host?(host)

    path = URI.parse(url).path
    !CompanyPage.asset_path?(path)
  rescue URI::InvalidURIError
    false
  end

  def initialize(name:, city:, country:)
    @name = name.to_s.gsub(/["\n\r]/, " ").squish.first(120)
    @city = city.to_s.gsub(/["\n\r]/, " ").squish.first(80)
    @country = country.to_s.upcase.presence
  end

  def pages
    return [] if @name.blank?

    _page, links = CompanyPage.new(search_url).read
    urls = self.class.targets_from(links)
    Rails.logger.info("[CompanyRegistry] #{@name}: #{urls.join(' ')}")
    urls.filter_map do |url|
      CompanyPage.fetch(url)
    rescue CompanyPage::Error
      nil
    end
  rescue CompanyPage::Error => error
    Rails.logger.warn("[CompanyRegistry] #{error.class}: #{error.message}")
    []
  end

  private

  def search_url
    terms = @country.nil? || @country == "PL" ? "NIP REGON KRS" : "company register VAT"
    query = [ @name, @city, terms ].compact_blank.join(" ")
    "#{SEARCH_URL}?q=#{CGI.escape(query)}"
  end
end
