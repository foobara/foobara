require "foobara/namespace"

require_relative "organization_module_extension"
require_relative "domain_module_extension"

module Foobara
  module Domain
    # TODO: should we just couple domain project and commands project to simplify this connection?
    # TODO: move this stuff to extensions/ directory
    module ModuleExtension
      class CannotBeOrganizationAndDomainAtSameTime < StandardError; end

      def foobara_domain!
        if foobara_organization?
          # :nocov:
          raise CannotBeOrganizationAndDomainAtSameTime
          # :nocov:
        end

        unless is_a?(Namespace::IsNamespace)
          foobara_namespace!
          foobara_autoset_namespace!(default_namespace: Foobara::GlobalOrganization)
          foobara_autoset_scoped_path!

          foobara_parent_namespace.foobara_register(self)
        end

        include(DomainModuleExtension)
      end

      def foobara_organization!
        if foobara_domain?
          # :nocov:
          raise CannotBeOrganizationAndDomainAtSameTime
          # :nocov:
        end

        include(OrganizationModuleExtension)

        unless is_a?(Namespace::IsNamespace)
          foobara_namespace!
          self.scoped_namespace = Namespace.global
          foobara_autoset_scoped_path!(make_top_level: true)

          foobara_parent_namespace.foobara_register(self)
        end
      end

      def foobara_domain?
        false
      end

      def foobara_organization?
        false
      end
    end
  end
end

Module.include(Foobara::Domain::ModuleExtension)

Foobara.foobara_organization!
