require_relative "version"

source "https://rubygems.org"
ruby Foobara::Version::MINIMUM_RUBY_VERSION
gemspec

# gem "foobara-util", path: "../util"

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
  gem "foobara-spec-helpers", "~> 0.0.1"
  gem "rspec-its"
  gem "simplecov"
end
