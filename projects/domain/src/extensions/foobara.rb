module Foobara
  class << self
    # TODO: rename this to manifest...
    # TODO: come up with a way to change a type's manifest... Or maybe treat Model very differently?
    def manifest
      {
        organizations: all_organizations.map(&:manifest_hash).inject(:merge)
      }
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
  end
end
