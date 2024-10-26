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

          # TODO: wow this is awkward. We should find a cleaner way to set children on namespaces.
          parent = foobara_parent_namespace
          parent.foobara_register(self)
          self.foobara_parent_namespace = parent
        end

        include(DomainModuleExtension)

        children = foobara_children
        children = children.sort_by { |child| child.scoped_path.size }

        # see if we are upgrading from prefix to domain and copy over types to Types module
        children.each do |child|
          next unless child.is_a?(Types::Type)

          types_mod_path = scoped_full_path.dup
          unless child.scoped_path.first == "Types"
            types_mod_path << "Types"
          end

          types_mod_path += child.scoped_path[..-2]
          types_mod = Util.make_module_p(types_mod_path.join("::"))

          # TODO: dry this up
          # TODO: this doesn't handle a type nested under a lower-case type for now
          if child.scoped_short_name =~ /^[a-z]/
            unless types_mod.respond_to?(child.scoped_short_name)
              types_mod.singleton_class.define_method child.scoped_short_name do
                child
              end

              unless types_mod.instance_variable_defined?(:@foobara_lowercase_constants)
                # TODO: test this path or delete it if unreachable
                # :nocov:
                types_mod.instance_variable_set(:@foobara_lowercase_constants, [])
                # :nocov:
              end

              types_mod.instance_variable_get(:@foobara_lowercase_constants) << child.scoped_short_name
            end
          else
            value = if types_mod.const_defined?(child.scoped_short_name, false)
                      # TODO: test this path or delete it if unreachable
                      # :nocov:
                      types_mod.const_get(child.scoped_short_name, false)
                      # :nocov:
                    end

            if value != child
              types_mod.send(:remove_const, child.scoped_short_name) if value
              # TODO: can we decouple this from the model project?
              new_value = if child.extends?("::model")
                            child.target_class
                          else
                            # TODO: test this path or delete it if unreachable
                            # :nocov:
                            child
                            # :nocov:
                          end
              types_mod.const_set(child.scoped_short_name, new_value)
            end
          end
        end
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

          # TODO: wow this is awkward. We should find a cleaner way to set children on namespaces.
          parent = foobara_parent_namespace
          parent.foobara_register(self)
          self.foobara_parent_namespace = parent
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
