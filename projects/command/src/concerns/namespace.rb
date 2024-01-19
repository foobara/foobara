module Foobara
  class Command
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

          def namespace
            # TODO: lets just couple this stuff. Currently this is overwritten by the extension.
            # :nocov:
            TypeDeclarations::TypeBuilder.current
            # :nocov:
          end
        end

        foobara_delegate :type_for_declaration, to: :class
      end
    end
  end
end
