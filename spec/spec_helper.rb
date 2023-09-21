require "bundler/setup"

require "pry"
require "pry-byebug"
require "rspec/its"

require "simplecov"

SimpleCov.start do
  # enable_coverage :branch
  minimum_coverage line: 100
  # TODO: enable this? worth it to get to 100% branch coverage?
  # minimum_coverage line: 100, branch: 100
end

require "foobara"

RSpec.configure do |config|
  config.filter_run_when_matching :focus

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.order = :defined

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # config.raise_errors_for_deprecations!
end

Foobara::Util.require_directory("#{__dir__}/support")
