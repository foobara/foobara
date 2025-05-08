module Foobara
  module Version
    VERSION = "0.0.119".freeze

    local_ruby_version = File.read("#{__dir__}/.ruby-version").chomp
    local_ruby_version_minor = local_ruby_version[/\A(\d+\.\d+)\.\d+\z/, 1]
    MINIMUM_RUBY_VERSION = ">= #{local_ruby_version_minor}.0".freeze
  end
end
