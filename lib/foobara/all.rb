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

  require "foobara/model_attribute_helpers"
  require "foobara/model_plumbing"
  # Shouldn't this be optional? Maybe use autoload feature somehow?
  require "foobara/in_memory_crud_driver"
  require "foobara/domain_mapper"
  require "foobara/manifest"

  install!
end
