module Foobara
  class CommandRegistry
    class ExposedOrganization
      foobara_instances_are_namespaces!

      include IsManifestable

      attr_accessor :organization_module

      def initialize(organization_module)
        self.organization_module = organization_module
        self.scoped_path = organization_module.scoped_path
      end

      def full_organization_name
        scoped_full_name
      end

      def organization_name
        @organization_name ||= Util.non_full_name(full_organization_name)
      end

      def full_organization_symbol
        @full_organization_symbol ||= Util.underscore_sym(full_organization_name)
      end

      # TODO: unable to address types here so it is handled as a hack higher up...
      def foobara_manifest(to_include:)
        organization_manifest = organization.foobara_manifest(to_include: Set.new)
        domains = foobara_all_domain(mode: Foobara::Namespace::LookupMode::DIRECT).map(&:full_domain_name)

        organization_manifest.merge(domains:)
      end
    end
  end
end
