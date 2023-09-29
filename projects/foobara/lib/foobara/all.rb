require "foobara/monorepo"

module Foobara
  module All
    # just makes Rubocop happy
  end

  module Monorepo
    # universal
    project "util"

    project "version"

    # could be independent projects
    projects "delegate",
             "concerns",
             "thread_parent",
             "weak_object_set",
             "enumerated",
             "callback",
             "state_machine"

    # various components of the foobara framework that have some level of coupling.
    # for example, Error in common knows about (or could be implemented to know about)
    # type declarations to expose its context type.
    projects "common",
             "value",
             "types",
             "type_declarations",
             "builtin_types",
             "domain",
             "model",
             "entity",
             "command",
             "persistence",
             "in_memory_crud_driver_minimal",
             "in_memory_crud_driver"

    install!
  end
end
