# frozen_string_literal: true

# Do not `require "sidekiq"` from application.rb or Bundler.require — that
# freezes autoload paths before turbo-rails finishes booting (FrozenError).
return if Rails.env.test?

require "sidekiq"
# Sidekiq::ActiveJob::Wrapper lives here. The adapter raises
# "uninitialized constant Sidekiq::ActiveJob" without it, because the gem
# is not auto-required.
require "sidekiq/rails"

redis = { url: Settings.redis_url.presence || "redis://localhost:6379/0" }

Sidekiq.configure_server do |config|
  config.redis = redis
  config[:backtrace_cleaner] = ->(backtrace) { Rails.backtrace_cleaner.clean(backtrace) }
end

Sidekiq.configure_client do |config|
  config.redis = redis
end

ActiveSupport.on_load(:active_job) do
  include Sidekiq::Job::Options unless respond_to?(:sidekiq_options)
end

Rails.application.config.after_initialize do
  ActiveJob::Base.queue_adapter = :sidekiq
end
