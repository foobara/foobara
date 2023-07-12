require "active_support/concern"
require "active_support/core_ext/array/wrap"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/string/inflections"

require "foobara/models/type"

load_files = lambda { |*path|
  pattern = File.join(__dir__, *path, "**", "*.rb")
  files = Dir[pattern].sort_by(&:length).reverse

  files.each { |f| require f }
}

load_files.call("..", "lib")
load_files.call

module Commands
end
