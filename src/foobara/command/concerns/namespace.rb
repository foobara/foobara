module Foobara
  class Command
    module Concerns
      module Namespace
        extend ActiveSupport::Concern

        class_methods do
          def type_for_declaration(...)
            namespace.type_for_declaration(...)
          end

          def namespace
            TypeDeclarations::Namespace.current
          end
        end

        delegate :type_for_declaration, to: :class
      end
    end
  end
end
