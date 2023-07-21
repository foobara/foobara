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

require "foobara/util"

require "foobara/error"
require "foobara/error_collection"
require "foobara/multiple_error"

require "foobara/outcome"

Foobara::Util.require_directory("#{__dir__}/../lib/foobara/enumerated")

require "foobara/callback"
Foobara::Util.require_directory("#{__dir__}/../lib/foobara/callback")

Foobara::Util.require_directory("#{__dir__}/../lib/foobara/state_machine")
require "foobara/state_machine"

Foobara::Util.require_directory("#{__dir__}/../lib/foobara/model")
require "foobara/model"

Foobara::Util.require_directory("#{__dir__}/../src/")

require "foobara/domain"
Foobara::Util.require_directory("#{__dir__}/../lib/foobara/domain")
