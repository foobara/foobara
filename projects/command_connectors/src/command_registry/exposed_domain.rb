module Foobara
  class CommandRegistry
    class ExposedDomain
      foobara_instances_are_namespaces!

      include TruncatedInspect
      include IsManifestable

      attr_accessor :domain_module

      def initialize(domain_module)
        self.domain_module = domain_module
        self.scoped_path = domain_module.scoped_path
      end

      # TODO: unable to address types here so it is handled as a hack higher up...
      def foobara_manifest(to_include: Set.new, remove_sensitive: true)
        to_include << foobara_organization

        domain_manifest = domain_module.foobara_manifest(to_include: Set.new)
        mode = Foobara::Namespace::LookupMode::DIRECT
        commands = foobara_all_command(mode:).map(&:foobara_manifest_reference).sort

        domain_manifest.merge(commands:)
      end

      def foobara_organization
        full_org_name = domain_module.foobara_organization.scoped_full_name
        root_registry.foobara_lookup_organization(full_org_name)
      end

      def root_registry
        parent = scoped_namespace
        parent = parent.scoped_namespace while parent.scoped_namespace
        parent
      end

      def foobara_manifest_reference
        domain_module.foobara_manifest_reference
      end
    end
  end
end
