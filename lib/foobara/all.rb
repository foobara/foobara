require "foobara/delegate"
# TODO: Weird to have both of these requiring each other...
require "foobara"

module Foobara
  # TODO: delete this but deprecate it for now to not break other projects
  Monorepo = Foobara

  module All
    # just makes Rubocop happy
    # TODO: delete this and make Rubocop exception in .rubocop.yml
  end

  require "foobara/delegate"
  require "foobara/state_machine"
  require "foobara/builtin_types"
  require "foobara/domain"
  require "foobara/command"
  # TODO: make it so these are fully decoupled, optional, and not required here
  require "foobara/model_attribute_helpers"
  require "foobara/model_plumbing"
  require "foobara/entities_plumbing"
  # Shouldn't this be optional? Maybe use autoload feature somehow?
  require "foobara/in_memory_crud_driver"
  require "foobara/domain_mapper"
  require "foobara/manifest"

  install!
end
