module Foobara
  class << self
    # TODO: come up with a way to change a type's manifest... Or maybe treat Model very differently?

    # Need to simplify this manifest into a reference/store structure
    def manifest
      # global_domains = [*foobara_all_domain(lookup_in_children: false), Domain.global]
      global_domains = foobara_all_domain(lookup_in_children: false)

      {
        organizations: foobara_all_organization.to_h do |organization|
          [organization.foobara_organization_name.to_sym, organization.foobara_manifest]
        end.merge(
          global_organization: {
            organization_name: "global_organization",
            domains: global_domains.map(&:foobara_manifest_hash).inject(:merge) || {}
          }
        )
      }
    rescue => e
      binding.pry
      raise
    end

    def all_domains
      foobara_all_domain
    end

    def all_commands
      Command.all
    end

    def all_types
      all_namespaces.map(&:all_types).flatten
    end

    def all_namespaces
      [*all_domains.map(&:foobara_type_namespace), TypeDeclarations::Namespace.global]
    end
  end
end
