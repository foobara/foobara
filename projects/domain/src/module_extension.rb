module Foobara
  class Domain
    # TODO: should we just couple domain project and commands project to simplify this connection?
    module ModuleExtension
      class CannotBeOrganizationAndDomainAtSameTime < StandardError; end

      def foobara_domain!
        if foobara_organization?
          # :nocov:
          raise CannotBeOrganizationAndDomainAtSameTime
          # :nocov:
        end

        # TODO: is this a smell?
        Domain.foobara_domain_modules << self

        include(DomainModuleExtension)
      end

      def foobara_organization!
        if foobara_domain?
          # :nocov:
          raise CannotBeOrganizationAndDomainAtSameTime
          # :nocov:
        end

        # TODO: is this a smell?
        Domain.foobara_organization_modules << self

        include(OrganizationModuleExtension)
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
