# frozen_string_literal: true

CarrierWave.configure do |config|
  config.storage = :file
  config.root = Rails.public_path
  config.enable_processing = !Rails.env.test?
end
