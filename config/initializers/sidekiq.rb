# frozen_string_literal: true

# Do not `require "sidekiq"` from application.rb or Bundler.require — that
# freezes autoload paths before turbo-rails finishes booting (FrozenError).
return if Rails.env.test?

require "sidekiq"

redis = { url: Settings.redis_url.presence || "redis://localhost:6379/0" }

Sidekiq.configure_server do |config|
  config.redis = redis
end

Sidekiq.configure_client do |config|
  config.redis = redis
end

Rails.application.config.after_initialize do
  ActiveJob::Base.queue_adapter = :sidekiq
end
