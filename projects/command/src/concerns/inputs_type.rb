module Foobara
  class Command
    module Concerns
      module InputsType
        include Concern

        module ClassMethods
          def inputs(...)
            old_inputs_type = inputs_type

            old_inputs_type&.possible_errors&.each do |possible_error|
              unregister_possible_error_if_registered(possible_error)
            end

            type = type_for_declaration(...)

            if type.extends?(BuiltinTypes[:model]) && !type.extends?(BuiltinTypes[:entity])
              type = type.element_types
            end

            @inputs_type = type

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
            # TODO: let's derive these at runtime and memoize...
            inputs_type.possible_errors.each do |possible_error|
              register_possible_error_class(possible_error)
            end
          end
        end

        foobara_delegate :inputs_type, :raw_inputs_type_declaration, to: :class
      end
    end
  end
end
