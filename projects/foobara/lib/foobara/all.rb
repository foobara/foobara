require "foobara/util"
# TODO: Weird to have both of these requiring each other...
require "foobara"

Foobara::Util.require_directory "#{__dir__}/../../src"

module Foobara
  # TODO: delete this but deprecate it for now to not break other projects
  Monorepo = Foobara

  module All
    # just makes Rubocop happy
    # TODO: delete this and make Rubocop exception in .rubocop.yml
  end

  # could be independent projects
  projects "delegate", # Let's just kill delegate
           "concerns",
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
           "entity",
           "model_attribute_helpers",
           "nested_transactionable",
           "command",
           "domain_mapper",
           "persistence", # Feels like this would be loaded before command?
           "in_memory_crud_driver_minimal",
           "in_memory_crud_driver",
           "manifest"

  install!
end
