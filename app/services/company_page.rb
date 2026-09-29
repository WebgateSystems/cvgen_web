# frozen_string_literal: true

require "net/http"
require "resolv"
require "ipaddr"
require "nokogiri"

class CompanyPage
  class Error < StandardError; end
  class InvalidUrl < Error; end
  class BlockedHost < Error; end
  class FetchFailed < Error; end

  Result = Data.define(:final_url, :title, :text)

  MAX_REDIRECTS = 4
  MAX_FOLLOW = 3
  OPEN_TIMEOUT = 8
  READ_TIMEOUT = 12
  MAX_BYTES = 750_000
  MAX_TEXT = 40_000
  USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
  SKIPPED_HOSTS = %w[
    justjoin.it justjoin.com pracuj.pl nofluffjobs.com theprotocol.it bulldogjob.com
    rocketjobs.pl linkedin.com indeed.com glassdoor.com olx.pl facebook.com instagram.com
    twitter.com x.com youtube.com google.com googletagmanager.com gstatic.com
    doubleclick.net schema.org cloudflare.com
  ].freeze

  PRIVATE_RANGES = [
    IPAddr.new("0.0.0.0/8"),
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("169.254.0.0/16"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("::1/128"),
    IPAddr.new("fc00::/7"),
    IPAddr.new("fe80::/10")
  ].freeze

  def self.fetch(url)
    new(url).read.first
  end

  # Source page plus a few company sites linked from it. Job boards stay out.
  def self.collect(url)
    source, links = new(url).read
    followed = followable_links(links, source.final_url).filter_map do |link|
      new(link).read.first
    rescue Error
      nil
    end
    [ source, *followed ]
  end

  def self.followable_links(links, source_url)
    source_host = registrable_host(source_url)
    seen = {}
    ranked = Array(links).filter_map do |link|
      uri = parse_link(link)
      next if uri.nil?

      host = registrable_host(uri.host)
      next if host.blank? || skipped_host?(host)
      next if asset_path?(uri.path)
      next if same_page?(uri, source_url)

      key = "#{host}#{uri.path}".downcase.chomp("/")
      next if seen[key]

      seen[key] = true
      [ link_score(uri, source_host), uri.to_s ]
    end
    ranked.sort_by { |score, href| [ score, href ] }.first(MAX_FOLLOW).map(&:last)
  end

  def self.registrable_host(value)
    host = value.to_s.include?("://") ? URI.parse(value).host : value
    host.to_s.downcase.sub(/\Awww\./, "")
  rescue URI::InvalidURIError
    ""
  end

  def self.skipped_host?(host)
    SKIPPED_HOSTS.any? { |suffix| host == suffix || host.end_with?(".#{suffix}") }
  end

  def self.asset_path?(path)
    path.to_s.match?(/\.(?:png|jpe?g|gif|webp|svg|css|js|pdf|zip|woff2?|ico)(?:\?|\z)/i)
  end

  def self.same_page?(uri, source_url)
    source = URI.parse(source_url)
    uri.host.to_s.casecmp?(source.host.to_s) && uri.path.chomp("/") == source.path.chomp("/")
  rescue URI::InvalidURIError
    false
  end

  def self.parse_link(link)
    uri = URI.parse(link.to_s)
    return unless uri.is_a?(URI::HTTP) && uri.host.present?

    uri.fragment = nil
    uri
  rescue URI::InvalidURIError
    nil
  end

  def self.link_score(uri, source_host)
    score = registrable_host(uri.host) == source_host ? 20 : 0
    score -= 10 if uri.path.to_s.match?(/career|about|contact|company|legal|imprint|kontakt|polityka/i)
    score
  end

  def initialize(url)
    @url = url.to_s.strip
  end

  def read
    uri = parse_public_http(@url)
    response, final_uri = get_following_redirects(uri)
    title, text, links = extract(response.body, final_uri)
    [ Result.new(final_url: final_uri.to_s, title: title, text: text), links ]
  end

  private

  def parse_public_http(value)
    uri = URI.parse(value)
    raise InvalidUrl unless uri.is_a?(URI::HTTP) && uri.host.present?
    raise BlockedHost if blocked_host?(uri.host)

    uri
  rescue URI::InvalidURIError
    raise InvalidUrl
  end

  def get_following_redirects(uri)
    MAX_REDIRECTS.times do
      response = request(uri)
      return [ response, uri ] if response.is_a?(Net::HTTPSuccess)

      location = response["location"]
      raise FetchFailed unless response.is_a?(Net::HTTPRedirection) && location.present?

      uri = parse_public_http(URI.join(uri, location).to_s)
    end
    raise FetchFailed
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError
    raise FetchFailed
  end

  def request(uri)
    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT
    ) do |http|
      http.request(Net::HTTP::Get.new(uri, { "User-Agent" => USER_AGENT, "Accept" => "text/html" }))
    end
  end

  def blocked_host?(host)
    addresses = begin
      IPAddr.new(host)
      [ host ]
    rescue IPAddr::InvalidAddressError
      Resolv.getaddresses(host)
    end
    return true if addresses.empty?

    addresses.any? { |address| private_address?(address) }
  rescue Resolv::ResolvError
    true
  end

  def private_address?(address)
    ip = IPAddr.new(address)
    PRIVATE_RANGES.any? { |range| range.include?(ip) }
  rescue IPAddr::InvalidAddressError
    true
  end

  def extract(body, base_uri)
    html = body.to_s.b[0, MAX_BYTES].to_s.dup.force_encoding("UTF-8")
    html = html.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    document = Nokogiri::HTML(html)
    links = links_from(document, html, base_uri)
    document.css("script, style, noscript").remove
    title = document.at("title")&.text.to_s.squish
    text = clip(document.at("body")&.text.to_s.gsub(/\s+/, " ").strip)
    [ title, text, links ]
  end

  def links_from(document, html, base_uri)
    hrefs = document.css("a[href]").map { |anchor| anchor["href"].to_s }
    hrefs += html.gsub("\\/", "/").scan(%r{https?://[^\s"'<>\\]+})
    hrefs.filter_map { |href| absolute_link(href, base_uri) }.uniq
  end

  def absolute_link(href, base_uri)
    return if href.blank? || href.start_with?("#", "mailto:", "javascript:", "tel:")

    self.class.parse_link(URI.join(base_uri, href).to_s)&.to_s
  rescue URI::InvalidURIError
    nil
  end

  def clip(text)
    return text if text.length <= MAX_TEXT

    head = 28_000
    "#{text.first(head)}\n…\n#{text.last(MAX_TEXT - head)}"
  end
end
