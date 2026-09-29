# frozen_string_literal: true

namespace :google_fonts do
  desc "Refresh config/data/google_fonts.json from the Fontsource Google catalog"
  task refresh: :environment do
    require "net/http"
    require "json"
    require "uri"

    uri = URI("https://api.fontsource.org/v1/fonts?type=google")
    response = Net::HTTP.get(uri)
    fonts = JSON.parse(response).map do |font|
      { "id" => font["id"], "family" => font["family"], "category" => font["category"] }
    end.uniq { |font| font["family"].downcase }.sort_by { |font| font["family"].downcase }

    raise "Roboto Condensed missing from Fontsource catalog" unless fonts.any? { |font| font["family"] == "Roboto Condensed" }

    path = Rails.root.join("config/data/google_fonts.json")
    path.write(JSON.generate(fonts) + "\n")
    puts "Wrote #{fonts.size} families to #{path}"
  end
end
