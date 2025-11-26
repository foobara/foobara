require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

desc "Run all tests with combined coverage"
task "spec:coverage" do
  require "simplecov"

  SimpleCov.root __dir__

  resultsets = Dir["coverage/*/.resultset.json"]

  SimpleCov.collate resultsets do
    minimum_coverage line: 100
  end
end

desc "Run command_connectors specs"
task "spec:command_connectors" do
  puts "Running command_connectors specs"
  Dir.chdir "#{__dir__}/foobara/projects/command_connectors" do
    sh "bundle exec rspec"
  end
end

desc "Run root specs"
task "spec:root" do
  puts "Running root specs"
  Dir.chdir __dir__ do
    sh "bundle exec rspec"
  end
end

task default: ["spec:root", "spec:command_connectors", :spec, "spec:coverage", :rubocop]
