module Foobara
  class Command < Service
    module Concerns
      module Namespace
        include Concern

        on_include do
          foobara_subclasses_are_namespaces!(default_parent: Foobara::GlobalDomain, autoregister: true)
        end

        module ClassMethods
          def type_for_declaration(...)
            domain.foobara_type_from_declaration(...)
          end

          def domain
            namespace = foobara_parent_namespace

            while namespace
              if namespace.is_a?(Module) && namespace.foobara_domain?
                d = namespace
                break
              end

              namespace = namespace.foobara_parent_namespace
            end

            d || GlobalDomain
          end

          # TODO: prefix these...
          def organization
            domain.foobara_organization
          end

          def full_command_name
            scoped_full_name
          end

          def full_command_symbol
            @full_command_symbol ||= Util.underscore_sym(full_command_name)
          end
        end

        foobara_delegate :type_for_declaration, to: :class
      end
    end
  end
end
