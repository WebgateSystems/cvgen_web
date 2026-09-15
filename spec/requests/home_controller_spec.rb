# frozen_string_literal: true

require "rails_helper"

RSpec.describe HomeController, type: :request do
  describe "GET /version" do
    before do
      allow(AppIdService).to receive(:version).and_return("hash_of_the_last_commit")
      get "/version"
    end

    it "responds with HTTP 200 status" do
      expect(response).to have_http_status(:ok)
    end

    it "responds with AppIdService.version as a plain string" do
      expect(response.body).to eq("hash_of_the_last_commit")
    end
  end

  describe "GET /version.json" do
    before do
      allow(AppIdService).to receive(:version).and_return("hash_of_the_last_commit")
      get "/version.json"
    end

    it "responds with HTTP 200 status" do
      expect(response).to have_http_status(:ok)
    end

    it "responds with JSON format" do
      expect(response.content_type).to include("application/json")
    end

    it "responds with AppIdService.version as JSON" do
      expect(response.parsed_body).to eq("version" => "hash_of_the_last_commit")
    end
  end

  describe "GET /health" do
    before { get "/health" }

    it "responds with HTTP 200 status" do
      expect(response).to have_http_status(:ok)
    end

    it "responds with OK as a plain string" do
      expect(response.body).to eq("OK")
    end
  end
end
