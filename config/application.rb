require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module CvgenWeb
  class Application < Rails::Application
    config.load_defaults 8.1

    # CarrierWave only — Active Storage / Action Text / Action Mailbox stay off.
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
      g.test_framework :rspec, fixtures: false
      g.fixture_replacement :factory_bot, dir: "spec/factories"
      g.system_tests = nil
    end

    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.available_locales = %i[en pl]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true
  end
end
