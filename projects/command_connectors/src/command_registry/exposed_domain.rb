module Foobara
  class CommandRegistry
    module ExposedDomain
      attr_reader :unexposed_domain

      def unexposed_domain=(unexposed_domain)
        @unexposed_domain = unexposed_domain
        self.scoped_path = unexposed_domain.scoped_path
      end

      # TODO: unable to address types here so it is handled as a hack higher up...
      def foobara_manifest
        to_include = TypeDeclarations.foobara_manifest_context_to_include

        if to_include
          to_include << foobara_organization
        end

        domain_manifest = TypeDeclarations.with_manifest_context(to_include: Set.new) do
          unexposed_domain.foobara_manifest
        end

        mode = Foobara::Namespace::LookupMode::DIRECT
        commands = foobara_all_command(mode:).map(&:foobara_manifest_reference).sort

        domain_manifest.merge(commands:)
      end

      def foobara_organization
        full_org_name = unexposed_domain.foobara_organization.scoped_full_name
        root_registry.foobara_lookup_organization(full_org_name)
      end

      def root_registry
        parent = scoped_namespace
        parent = parent.scoped_namespace while parent.scoped_namespace
        parent
      end

      def foobara_manifest_reference
        unexposed_domain.foobara_manifest_reference
      end
    end
  end
end
