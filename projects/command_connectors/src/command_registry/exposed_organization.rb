module Foobara
  class CommandRegistry
    module ExposedOrganization
      attr_reader :unexposed_organization

      def unexposed_organization=(unexposed_organization)
        @unexposed_organization = unexposed_organization
        self.scoped_path = unexposed_organization.scoped_path
      end

      # TODO: unable to address types here so it is handled as a hack higher up...
      def foobara_manifest
        organization_manifest = unexposed_organization.foobara_manifest
        mode = Foobara::Namespace::LookupMode::DIRECT
        domains = foobara_all_domain(mode:).map(&:foobara_manifest_reference).sort

        organization_manifest.merge(domains:)
      end

      def foobara_manifest_reference
        unexposed_organization.foobara_manifest_reference
      end
    end
  end
end
