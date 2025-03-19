module Foobara
  class CommandRegistry
    class ExposedOrganization
      foobara_instances_are_namespaces!

      include TruncatedInspect
      include IsManifestable

      attr_accessor :organization_module

      def initialize(organization_module)
        self.organization_module = organization_module
        self.scoped_path = organization_module.scoped_path
      end

      # TODO: unable to address types here so it is handled as a hack higher up...
      def foobara_manifest(to_include: Set.new, remove_sensitive: true)
        organization_manifest = organization_module.foobara_manifest(to_include: Set.new, remove_sensitive:)
        mode = Foobara::Namespace::LookupMode::DIRECT
        domains = foobara_all_domain(mode:).map(&:foobara_manifest_reference).sort

        organization_manifest.merge(domains:)
      end

      def foobara_manifest_reference
        organization_module.foobara_manifest_reference
      end
    end
  end
end
