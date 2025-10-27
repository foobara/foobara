ENV["FOOBARA_ENV"] = "test"

require "bundler/setup"

unless ENV["SKIP_PRY"] == "true" || ENV["CI"] == "true"
  require "pry"
  require "pry-byebug"
end

require "rspec/its"
require "simplecov"

SimpleCov.start do
  add_filter "spec/support/"
  # enable_coverage :branch
  minimum_coverage line: 100
  # TODO: enable this? worth it to get to 100% branch coverage?
  # minimum_coverage line: 100, branch: 100
end

require "foobara/all"
require "foobara/command_connectors"

RSpec.configure do |config|
  # Need to do :all instead of :each because for specs that use .around,
  # .after(:each) do |example| here is called after example.run but before any threads created in
  # .around might have been cleaned up.
  config.after(:suite) do
    expect(Thread.list.size).to eq(1)
  end
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
