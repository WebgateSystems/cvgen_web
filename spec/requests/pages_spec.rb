# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public site", type: :request do
  it "renders the landing page" do
    get root_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("CVGen")
  end

  it "stores a locale cookie and redirects back" do
    get locale_path(locale: :pl), headers: { "HTTP_REFERER" => root_url }
    expect(response).to redirect_to(root_url)
    expect(response.cookies["locale"]).to eq("pl")
  end

  it "ignores an unknown locale" do
    get locale_path(locale: :de)
    expect(response).to redirect_to(root_path)
    expect(response.cookies["locale"]).to be_blank
  end

  it "uses the locale cookie on the next request" do
    get root_path, headers: { "HTTP_COOKIE" => "locale=pl" }
    expect(response.body).to include("Studio CV")
  end
end
