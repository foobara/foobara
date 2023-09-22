module Foobara
  class << self
    def require_file(project, path)
      Util.require_project_file(project, path)
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
end
