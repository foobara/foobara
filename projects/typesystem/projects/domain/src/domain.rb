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
          elsif object == Namespace.global
            GlobalDomain
          elsif object.scoped_path_set? && object.scoped_path.empty?
            object.foobara_lookup_domain!("")
          else
            to_domain(object.scoped_namespace)
          end
        else
          # :nocov:
          raise NoSuchDomain, "Couldn't determine domain for #{object}"
          # :nocov:
        end
      end

      def domain_through_modules(mod)
        mod = Util.module_for(mod)

        while mod
          if mod.foobara_domain?
            namespace = mod
            break
          end

          mod = Util.module_for(mod)
        end

        if namespace&.foobara_domain?
          namespace
        else
          GlobalDomain
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

      def copy_constants(old_mod, new_class)
        old_mod.constants.each do |const_name|
          value = old_mod.const_get(const_name)
          if new_class.const_defined?(const_name)
            to_replace = new_class.const_get(const_name)
            if to_replace != value
              new_class.send(:remove_const, const_name)
              new_class.const_set(const_name, value)
            end
          else
            new_class.const_set(const_name, value)
          end
        end
      end
    end
  end
end
