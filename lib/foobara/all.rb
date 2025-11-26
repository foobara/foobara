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

  project_path = "#{__dir__}/../../projects/typesystem"

  # could be independent projects
  # but these are stored in typesystem for now
  projects("concerns",
           "enumerated",
           "callback",
           "state_machine",
           "namespace",
           project_path:)

  # various components of the foobara framework that have some level of coupling.
  # for example, Error in common knows about (or could be implemented to know about)
  # type declarations to expose its context type.

  # Remaining pieces the typesystem depends on
  projects("domain",
           "common",
           "value",
           "types",
           "type_declarations",
           "builtin_types",
           project_path:)

  project_path = "#{__dir__}/../../projects/entities"

  # The goal is to make these parts optional and extract them to allow
  # one to use foobara as a lighter-weight service object layer if desired
  # in a project that already has a different ORM
  projects("model",
           "detached_entity",
           "entity",
           # only used by entity persistence so loading it here
           "weak_object_set",
           "persistence",
           "nested_transactionable",
           "model_attribute_helpers",
           "in_memory_crud_driver_minimal",
           "in_memory_crud_driver",
           project_path:)

  project_path = "#{__dir__}/../.."

  # Not represented here is command_connectors which is lazily-loaded to make scripts faster
  projects("command",
           "domain_mapper",
           "manifest",
           project_path:)

  install!
end
