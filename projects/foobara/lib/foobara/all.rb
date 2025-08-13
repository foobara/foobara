require "foobara/util"
# TODO: Weird to have both of these requiring each other...
require "foobara"

Foobara::Util.require_directory "#{__dir__}/../../src"

module Foobara
  # TODO: deprecate this somehow?
  Monorepo = Foobara

  module All
    # just makes Rubocop happy
    # TODO: delete this and make Rubocop exception in .rubocop.yml
  end

  # could be independent projects
  projects "delegate", # Let's just kill delegate
           "concerns",
           # This doesn't really seem to be generic because it has an odd use-case
           # of needing to update entities when they acquire a primary key.
           "weak_object_set",
           "enumerated",
           "callback",
           "state_machine",
           "namespace"

  # various components of the foobara framework that have some level of coupling.
  # for example, Error in common knows about (or could be implemented to know about)
  # type declarations to expose its context type.
  projects "domain",
           "common",
           "value",
           "types",
           "type_declarations",
           "builtin_types",
           "model",
           "detached_entity",
           # Want to get entity into its own repository with presistence, hmmm...
           "entity",
           "persistence",
           "nested_transactionable",
           "model_attribute_helpers",
           "in_memory_crud_driver_minimal",
           "in_memory_crud_driver",
           "command",
           "domain_mapper",
           "manifest"

  install!
end
