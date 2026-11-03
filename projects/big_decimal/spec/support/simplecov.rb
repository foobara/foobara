require "simplecov"

SimpleCov.start do
  add_filter "spec/support"
  enable_coverage :branch
  minimum_coverage line: 100, branch: 100
end
