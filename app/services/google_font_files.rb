# frozen_string_literal: true

require "net/http"
require "uri"
require "openssl"

class GoogleFontFiles
  CDN = "https://cdn.jsdelivr.net/fontsource/fonts"
  USER_AGENT = "cvgen-web"
  PRIMARY_VARIANT = "latin-400-normal"
  VARIANTS = %w[
    latin-ext-400-normal
    latin-ext-700-normal
    latin-400-normal
    latin-700-normal
    latin-ext-400-italic
    latin-400-italic
  ].freeze

  def self.prepare!(root, theme_data)
    if defined?(Cvgen::FontResolver)
      Cvgen::FontResolver.prepare!(root, theme_data, GoogleFontsCatalog.ids_by_family)
    else
      new(root, theme_data).prepare!
    end
  end

  def self.cache_dir
    Pathname(ENV.fetch("CVGEN_FONT_CACHE", Rails.root.join("tmp/google-fonts").to_s))
  end

  def self.fetch(url, limit = 5)
    raise CvGenerator::Error, "font download redirect limit exceeded" if limit <= 0

    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 30
    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = USER_AGENT
    response = http.request(request)

    case response
    when Net::HTTPSuccess
      response.body
    when Net::HTTPNotFound
      nil
    when Net::HTTPRedirection
      location = response["location"].to_s
      raise CvGenerator::Error, "font download redirect missing location" if location.empty?

      fetch(URI.join(url, location).to_s, limit - 1)
    else
      raise CvGenerator::Error, "font download failed (#{response.code}): #{url}"
    end
  rescue Timeout::Error, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, OpenSSL::SSL::SSLError => e
    raise CvGenerator::Error, "font download failed: #{e.message}"
  end

  def initialize(root, theme_data)
    @root = Pathname(root)
    @theme_data = theme_data || {}
  end

  def prepare!
    families.each { |family| resolve_family!(family) }
  end

  private

  def families
    fonts = @theme_data["fonts"] || {}
    [ fonts["heading"], fonts["body"] ].map { |value| value.to_s.strip }.reject(&:empty?).uniq
  end

  def resolve_family!(family)
    id = GoogleFontsCatalog.google_id(family)
    return if id.blank?

    cache = self.class.cache_dir.join(id)
    dest = @root.join("fonts", id)
    primary = "#{PRIMARY_VARIANT}.ttf"
    cached_primary = cache.join(primary)

    unless cached_primary.exist? && cached_primary.size.positive?
      body = self.class.fetch("#{CDN}/#{id}@latest/#{primary}")
      # i18n-tasks-use t('jobseeker.themes.font_missing')
      raise CvGenerator::Error, I18n.t("jobseeker.themes.font_missing", family: family) if body.nil?

      FileUtils.mkdir_p(cache)
      cached_primary.binwrite(body)
    end

    FileUtils.mkdir_p(dest)
    FileUtils.cp(cached_primary, dest.join(primary))

    (VARIANTS - [ PRIMARY_VARIANT ]).each do |variant|
      filename = "#{variant}.ttf"
      cached = cache.join(filename)
      unless cached.exist? && cached.size.positive?
        body = self.class.fetch("#{CDN}/#{id}@latest/#{filename}")
        next if body.nil?

        FileUtils.mkdir_p(cache)
        cached.binwrite(body)
      end
      FileUtils.cp(cached, dest.join(filename)) if cached.exist? && cached.size.positive?
    end
  end
end
