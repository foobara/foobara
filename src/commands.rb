require "active_support/concern"
require "active_support/core_ext/array/wrap"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/string/inflections"

# TODO: do we really want this module/project name?
module Commands
end

# TODO: break these out into separate gems instead of simulating it here
require "foobara"
require "foobara/enumerated"
require "foobara/callback"
require "foobara/state_machine"
require "foobara/type"
require "foobara/model"

Foobara::Util.require_directory("#{__dir__}/../src/")

# would have made more sense for domain to have been the top of this monorepo. Oh well, can break everything out later.
require "foobara/domain"
