source "https://rubygems.org"

gem "config"
gem "devise", "~> 5.0"
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection"
gem "omniauth-google-oauth2"
gem "omniauth-apple"
gem "omniauth-facebook"
gem "omniauth-linkedin-oauth2"
gem "rails", "~> 8.1.3", ">= 8.1.3.1"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "cssbundling-rails"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

gem "bootsnap", require: false
gem "thruster", require: false
gem "carrierwave", "~> 3.1"
gem "cvgen", github: "WebgateSystems/cvgen"
gem "openai", "~> 0.6.0"
gem "pdf-reader", "~> 2.14"
gem "rubyzip", "~> 3.0"
gem "sidekiq", "~> 7.3", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails"
end

group :development do
  gem "brakeman", require: false
  gem "bundle-audit", require: false

  # Deploy with Capistrano
  gem "bot-notifier", "~> 3.1.0", github: "WebgateSystems/bot-notifier", require: false
  gem "cape"
  gem "capistrano3-puma", github: "seuros/capistrano-puma"
  gem "capistrano-hook", require: false
  gem "capistrano-nvm", require: false
  gem "capistrano-rails"
  gem "capistrano-rvm"

  gem "fasterer", require: false
  gem "i18n-tasks"
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "simplecov", "~> 0.22", require: false
end
