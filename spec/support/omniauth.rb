# frozen_string_literal: true

OmniAuth.config.test_mode = true

RSpec.configure do |config|
  config.before do
    %i[google_oauth2 apple facebook linkedin].each do |provider|
      OmniAuth.config.mock_auth[provider] = nil
    end
  end
end
