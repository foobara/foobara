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

        include(DomainModuleExtension)

        foobara_namespace!
        foobara_autoset_namespace!(default_namespace: Foobara)
        foobara_autoset_scoped_path!

        # TODO: wow this is awkward. We should find a cleaner way to set children on namespaces.
        parent = foobara_parent_namespace
        parent.foobara_register(self)
        self.foobara_parent_namespace = parent
      end

      def foobara_organization!
        if foobara_domain?
          # :nocov:
          raise CannotBeOrganizationAndDomainAtSameTime
          # :nocov:
        end

        include(OrganizationModuleExtension)

        # TODO: remove this hack
        return if self == Foobara

        foobara_namespace!
        foobara_autoset_namespace!(default_namespace: Foobara)
        foobara_autoset_scoped_path!

        # TODO: wow this is awkward. We should find a cleaner way to set children on namespaces.
        parent = foobara_parent_namespace
        parent.foobara_register(self)
        self.foobara_parent_namespace = parent
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
