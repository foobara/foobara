module Foobara
  class << self
    # TODO: come up with a way to change a type's manifest... Or maybe treat Model very differently?

    # Need to simplify this manifest into a reference/store structure
    def manifest
      global_domains = [*foobara_all_domain(lookup_in_children: false).map(&:foobara_domain), Domain.global]

      {
        organizations: foobara_all_organization.to_h do |organization|
          [organization.foobara_organization_name.to_sym, organization.foobara_manifest]
        end.merge(
          global_organization: {
            organization_name: "global_organization",
            domains: global_domains.map(&:manifest_hash).inject(:merge) || {}
          }
        )
      }
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
