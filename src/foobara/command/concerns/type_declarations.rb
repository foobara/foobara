require "foobara/command/runtime_error"

module Foobara
  class Command
    module Concerns
      module TypeDeclarations
        extend ActiveSupport::Concern

        class_methods do
          def type_declaration_handler_registry
            # TODO: do something more sophisticated here
            Foobara::TypeDeclarations.global_type_declaration_handler_registry
          end
        end

        delegate :type_declaration_handler_registry, to: :class
      end
    end
  end
end
