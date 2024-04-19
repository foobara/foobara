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

        include(DomainModuleExtension)

        unless is_a?(Namespace::IsNamespace)
          foobara_namespace!
          foobara_autoset_namespace!(default_namespace: Foobara::GlobalOrganization)
          foobara_autoset_scoped_path!

          # TODO: wow this is awkward. We should find a cleaner way to set children on namespaces.
          parent = foobara_parent_namespace
          parent.foobara_register(self)
          self.foobara_parent_namespace = parent

          _patch_up_children(self)
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
          _patch_up_children(self)
        end
      end

      def foobara_domain?
        false
      end

      def foobara_organization?
        false
      end

      # TODO: moved to Scoped or Namespace
      def _patch_up_children(mod)
        # how to do this?
        # I guess we could just iterate over all objects and patch up any with matching prefixes
        Foobara.foobara_root_namespace.foobara_each do |scoped|
          parent = scoped.scoped_namespace
          next if parent == mod

          if parent
            next if _start_with?(parent.scoped_full_path, mod.scoped_full_path)
          end

          if _start_with?(scoped.scoped_full_path, mod.scoped_full_path)
            scoped.scoped_path = scoped.scoped_full_path[mod.scoped_full_path.size..]

            if parent
              parent.foobara_unregister(scoped)

              mod.foobara_register(scoped)

              if scoped.is_a?(Namespace::IsNamespace)
                scoped.foobara_parent_namespace = mod
              else
                scoped.scoped_namespace = mod
              end
            end
          end
        end
      end

      # TODO: move to util
      def _start_with?(large_array, small_array)
        return false unless large_array.size > small_array.size

        small_array.each.with_index do |item, index|
          return false unless large_array[index] == item
        end

        true
      end
    end
  end
end

Module.include(Foobara::Domain::ModuleExtension)

Foobara.foobara_organization!
