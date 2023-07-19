require "bundler/setup"

require "pry"
require "pry-byebug"
require "rspec/its"

require "commands"

RSpec.configure do |config|
  config.filter_run_when_matching :focus

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

pattern = File.join(__dir__, "support", "**", "*.rb")
files = Dir[pattern].sort_by(&:length).reverse

files.each { |f| require f }
