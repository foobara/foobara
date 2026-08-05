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
            # simplecov:disable
            raise NoSuchOrganization, "Couldn't determine organization for #{object}"
            # simplecov:enable
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
          # simplecov:disable
          raise NoSuchOrganization, "Couldn't determine organization for #{object}"
          # simplecov:enable
        end
      end

      def create(full_organization_name)
        if Organization.to_organization(full_organization_name)
          # simplecov:disable
          raise OrganizationAlreadyExistsError, "Organization #{full_organization_name} already exists"
          # simplecov:enable
        end
      rescue Organization::NoSuchOrganization
        Util.make_module_p(full_organization_name) { foobara_organization! }
      end
    end
  end
end
