ENV["FOOBARA_ENV"] = "test"

require "bundler/setup"
Warning[:deprecated] = true

if ENV["RUBY_DEBUG"] == "true"
  require "debug"
elsif ENV["SKIP_PRY"] != "true" && ENV["CI"] != "true"
  require "pry"
  require "pry-byebug" unless ENV["SKIP_BYEBUG"] == "true"
end

require "rspec/its"
require_relative "support/simplecov"

require "foobara/big_decimal"

Foobara.install!

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

require "foobara/spec_helpers/all"
Dir["#{__dir__}/support/**/*.rb"].each { |f| require f }
