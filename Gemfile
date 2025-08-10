require_relative "version"

source "https://rubygems.org"
ruby Foobara::Version::MINIMUM_RUBY_VERSION
gemspec

# gem "foobara-util", path: "../util"
# gem "inheritable-thread-vars", path: "../inheritable-thread-vars"
# gem "foobara-lru-cache", path: "../lru-cache"

group :development do
  gem "foobara-rubocop-rules", ">= 1.0.0"
  gem "guard-rspec"
  gem "rake"
  gem "rubocop-rake"
  gem "rubocop-rspec"
end

group :development, :test do
  gem "pry"
  gem "pry-byebug"
  gem "rspec"
  gem "ruby-prof"
end

group :test do
  gem "foobara-crud-driver-spec-helpers", "< 2.0.0" # , path: "../crud-driver-spec-helpers"
  gem "foobara-spec-helpers", "< 2.0.0" # , path: "../spec-helpers"
  gem "rspec-its"
  gem "simplecov"
end
