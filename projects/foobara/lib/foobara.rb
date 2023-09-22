module Foobara
  class << self
    def require_file(project, path)
      Util.require_project_file(project, path)
    end

    def require_project(*projects)
      projects.each do |project|
        require "foobara/#{project}"
      end
    end

    # TODO: rename this to manifest...
    # TODO: come up with a way to change a type's manifest... Or maybe treat Model very differently?
    def manifest
      all_organizations.map(&:manifest_hash).inject(:merge)
    end

    def all_organizations
      Organization.all
    end

    def all_domains
      Domain.all.values
    end

    def all_commands
      Command.all
    end

    def all_types
      all_namespaces.map(&:all_types).flatten
    end

    def all_namespaces
      [*all_domains.map(&:type_namespace), TypeDeclarations::Namespace.global]
    end

    def reset_alls
      Domain.reset_all
      Model.reset_all
      Entity.reset_all
      Command.reset_all
      Organization.reset_all
      Types.reset_all
      TypeDeclarations.reset_all
      BuiltinTypes.reset_all
      Persistence.reset_all
    end
  end

  # universal
  require_project "util"

  Util.require_directory("#{__dir__}/../src")

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
