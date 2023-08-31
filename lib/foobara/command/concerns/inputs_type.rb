module Foobara
  class Command
    module Concerns
      module InputsType
        extend ActiveSupport::Concern

        class_methods do
          def inputs(inputs_type_declaration)
            @inputs_type = type_for_declaration(inputs_type_declaration)

            register_possible_input_errors

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

          def inputs_type_declaration
            inputs_type.declaration_data
          end

          private

          def register_possible_input_errors
            # TODO: can destructure here or no?
            inputs_type.possible_errors.each_pair do |key, error_class|
              register_possible_error_class(key, error_class)
            end
          end
        end

        delegate :inputs_type, :raw_inputs_type_declaration, to: :class
      end
    end
  end
end
