require 'simplecov'
require 'aruba/rspec'
require 'webmock/rspec'

require_relative 'support/custom_expectations/write_expectations'

RSpec.configure do |config|
  config.include Aruba::Api

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true # rspec 4.0 default
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true # rspec 4.0 default
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups # rspec 4.0 default

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # This setting enables warnings. It's recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  config.warnings = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random
end

Aruba.configure do |config|
  # Use aruba working directory
  config.home_directory = File.join(config.root_directory, config.working_directory)
  config.command_launcher = :in_process

  require 'buchungsstreber/cli/runner'
  config.main_class = Buchungsstreber::CLI::Runner

  # We're mocking paths differently
  config.allow_absolute_paths = true
end

WebMock.disable_net_connect!(net_http_connect_on_start: true)
