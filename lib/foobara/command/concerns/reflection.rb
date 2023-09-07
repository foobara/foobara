module Foobara
  class Command
    module Concerns
      module Reflection
        extend ActiveSupport::Concern

        class_methods do
          def to_h
            h = {
              command_name:,
              inputs_type: inputs_type&.declaration_data,
              error_types: errors_type_declaration,
              depends_on: depends_on.map(&:name).to_a
            }

            if result_type
              h.merge!(result_type: result_type.declaration_data)
            end

            h
          end

          def command_name
            name.demodulize
          end
        end

        delegate :type_for_declaration, to: :class
      end
    end
  end
end
