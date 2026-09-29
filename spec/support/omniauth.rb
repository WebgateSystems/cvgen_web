# frozen_string_literal: true

require "logger"

OmniAuth.config.test_mode = true
# Mock failures (`:invalid_credentials`) always log ERROR to stderr otherwise.
OmniAuth.config.logger = Logger.new(File::NULL)

RSpec.configure do |config|
  config.before do
    %i[google_oauth2 apple facebook linkedin].each do |provider|
      OmniAuth.config.mock_auth[provider] = nil
    end
  end
end
