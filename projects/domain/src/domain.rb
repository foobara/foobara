module Foobara
  module Domain
    class DomainAlreadyExistsError < StandardError; end
    class OrganizationAlreadyExistsError < StandardError; end

    class << self
      def create(full_domain_name)
        if Domain.to_domain(full_domain_name)
          raise DomainAlreadyExistsError, "Domain #{full_domain_name} already exists"
        end
      rescue Domain::NoSuchDomain
        begin
          Util.make_module(full_domain_name) { foobara_domain! }
        rescue Util::ParentModuleDoesNotExistError => e
          # TODO: this doesn't feel like the right logic... how do we know this isn't a prefix instead of an
          # organization?
          Util.make_module(e.parent_name) { foobara_organization! }
          Util.make_module(full_domain_name) { foobara_domain! }
        end
      end

      def create_organization(full_organization_name)
        if Domain.to_organization(full_organization_name)
          # :nocov:
          raise OrganizationAlreadyExistsError, "Organization #{full_organization_name} already exists"
          # :nocov:
        end
      rescue Domain::NoSuchOrganization
        Util.make_module_p(full_organization_name) { foobara_organization! }
      end

      def foobara_type_from_declaration(scoped, type_declaration)
        domain = to_domain(scoped)

        domain.foobara_type_from_declaration(type_declaration)
      end

      def current
        to_domain(Namespace.current)
      end
    end
  end
end
