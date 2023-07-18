require "active_support/concern"
require "active_support/core_ext/array/wrap"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/string/inflections"

module Commands
end

lib_files = Dir["#{__dir__}/../lib/**/*.rb"].sort_by(&:length).reverse
src_files = Dir["#{__dir__}/**/*.rb"].sort_by(&:length).reverse

type, lib_files = lib_files.partition { |f| f.end_with?("lib/foobara/model/type.rb") }
lib_files, domain_files = lib_files.partition { |f| f !~ %r{\.\./lib/foobara/domain(/|\.rb)} }

[type, lib_files, src_files, domain_files].flatten.each { |f| require f }
