module Foobara
  class CommandRegistry
    class ExposedOrganization
      include Scoped
      include IsManifestable

      attr_accessor :organization_module,
                    :scoped_path,
                    :scoped_namespace

      def initialize(organization_module, exposed_organization:, scoped_path: nil)
        self.organization_module = organization_module
        self.scoped_path = scoped_path || organization_module.scoped_path
        self.scoped_namespace = exposed_organization
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

      def foobara_manifest(to_include:)
        organization_module.foobara_manifest(to_include:).merge(super).merge(
          Util.remove_blank(
            scoped_category: :organization,
            full_organization_name:
          )
        )
      end
    end
  end
end
