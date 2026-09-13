# frozen_string_literal: true

require "simplecov"

SimpleCov.start "rails" do
  enable_coverage :branch
  track_files "app/**/*.rb"
  add_filter %r{^/spec/}
  add_filter %r{^/config/}
  add_filter %r{^/db/}
  add_filter %r{^/vendor/}
  add_filter "app/jobs/"
  add_filter "app/mailers/"
  add_group "Services", "app/services"
  add_group "Uploaders", "app/uploaders"
  # Enforce on the full suite / CI. Skip with COVERAGE=false when running a single file.
  minimum_coverage 90 unless ENV["COVERAGE"] == "false"
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "tmp/rspec-examples.txt"
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
