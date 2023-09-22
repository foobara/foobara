module Foobara
  class Command
    module Concerns
      module Namespace
        include Concern

        module ClassMethods
          def type_for_declaration(...)
            namespace.type_for_declaration(...)
          end

          def namespace
            # TODO: lets just couple this stuff. Currently this is overwritten by the extension.
            # :nocov:
            TypeDeclarations::Namespace.current
            # :nocov:
          end
        end

        foobara_delegate :type_for_declaration, to: :class
      end
    end
  end
end
