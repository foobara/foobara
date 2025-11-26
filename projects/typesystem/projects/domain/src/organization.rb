module Foobara
  module Organization
    class OrganizationAlreadyExistsError < StandardError; end
    class NoSuchOrganization < StandardError; end

    class << self
      def to_organization(object)
        case object
        when nil
          GlobalOrganization
        when ::String, ::Symbol
          organization = Namespace.global.foobara_lookup_organization(object)

          unless organization
            # :nocov:
            raise NoSuchOrganization, "Couldn't determine organization for #{object}"
            # :nocov:
          end

          organization
        when Foobara::Scoped
          if object.is_a?(Module) && object.foobara_organization?
            object
          else
            parent = object.scoped_namespace

            if parent
              to_organization(parent)
            else
              GlobalOrganization
            end
          end
        else
          # :nocov:
          raise NoSuchOrganization, "Couldn't determine organization for #{object}"
          # :nocov:
        end
      end

      def create(full_organization_name)
        if Organization.to_organization(full_organization_name)
          # :nocov:
          raise OrganizationAlreadyExistsError, "Organization #{full_organization_name} already exists"
          # :nocov:
        end
      rescue Organization::NoSuchOrganization
        Util.make_module_p(full_organization_name) { foobara_organization! }
      end
    end
  end
end
