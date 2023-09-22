module Foobara
  class << self
    def require_project(*projects)
      projects.each { |project| require "foobara/#{project}" }
    end

    def load_project(project_dir)
      project = project_dir[/([^\/]+)\/lib(\/|$)/, 1]
      Util.require_directory("#{__dir__}/../../#{project}/src")
    end
  end

  # universal
  require_project "util"

  load_project(__dir__)

  # could be independent projects
  require_project "concerns",
                  "thread_parent",
                  "weak_object_set",
                  "enumerated",
                  "callback",
                  "state_machine"

  # various components of the foobara framework that have some level of coupling.
  # for example, Error in common knows about (or could be implemented to know about)
  # type declarations to expose its context type.
  require_project "common",
                  "value",
                  "types",
                  "type_declarations",
                  "builtin_types",
                  "domain",
                  "entity",
                  "command",
                  "persistence"

  Domain.install!
end
