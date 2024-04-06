module Foobara
  module Domain
    class DomainAlreadyExistsError < StandardError; end

    class << self
      def to_domain(object)
        case object
        when nil
          global
        when ::String, ::Symbol
          domain = Namespace.global.foobara_lookup_domain(object)

          unless domain
            # :nocov:
            raise NoSuchDomain, "Couldn't determine domain for #{object}"
            # :nocov:
          end

          domain
        when Foobara::Scoped
          if object.is_a?(Module) && object.foobara_domain?
            object
          else
            parent = object.scoped_namespace

            if parent
              to_domain(parent)
            else
              GlobalDomain
            end
          end
        else
          # :nocov:
          raise NoSuchDomain, "Couldn't determine domain for #{object}"
          # :nocov:
        end
      end

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
