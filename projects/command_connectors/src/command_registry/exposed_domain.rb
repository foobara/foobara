module Foobara
  class CommandRegistry
    class ExposedDomain
      include Scoped
      include IsManifestable

      attr_accessor :domain_module,
                    :scoped_path,
                    :scoped_namespace

      def initialize(domain_module, exposed_organization:)
        self.domain_module = domain_module
        self.scoped_path = domain_module.scoped_path
        self.scoped_namespace = exposed_organization
      end

      def full_domain_name
        scoped_full_name
      end

      def domain_name
        @domain_name ||= Util.non_full_name(full_domain_name)
      end

      def full_domain_symbol
        @full_domain_symbol ||= Util.underscore_sym(full_domain_name)
      end

      def foobara_manifest(to_include:)
        domain_module.foobara_manifest(to_include:).merge(super).merge(
          Util.remove_blank(
            scoped_category: :domain,
            full_domain_name:
          )
        )
      end
    end
  end
end
