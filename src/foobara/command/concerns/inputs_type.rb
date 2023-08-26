module Foobara
  class Command
    module Concerns
      module InputsType
        extend ActiveSupport::Concern

        class_methods do
          def inputs(inputs_type_declaration)
            @inputs_type = type_for_declaration(inputs_type_declaration)

            if defined?(@error_context_type_map)
              update_input_error_context_type_map
            end

            register_possible_errors

            @inputs_type
          end

          def inputs_type
            return @inputs_type if defined?(@inputs_type)

            @inputs_type = if superclass < Foobara::Command
                             superclass.inputs_type
                           end
          end

          def raw_inputs_type_declaration
            inputs_type.raw_declaration_data
          end

          private

          def register_possible_errors(path = [], type = inputs_type)
            type.possible_errors.each do |possible_error|
              p = possible_error[0]
              symbol = possible_error[1]
              error_class = possible_error[2]

              context_type_declaration = TypeDeclarations.error_context_type_declaration(error_class)

              possible_input_error([*path, *p], symbol, context_type_declaration)
            end
          end
        end

        delegate :inputs_type, :raw_inputs_type_declaration, to: :class
      end
    end
  end
end
