require "active_support/concern"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/string/inflections"

require "foobara/models/type"

pattern = File.join(__dir__, "lib", "**", "*.rb")

files = Dir[pattern].sort_by(&:length).reverse

files.each do |path|
  require path
end