module Foobara
  module CommandPatternImplementation
    module Concerns
      module InputsType
        include Concern

        module ClassMethods
          def inputs(...)
            old_inputs_type = inputs_type

            old_inputs_type&.possible_errors&.each do |possible_error|
              unregister_possible_error_if_registered(possible_error)
            end

            if defined?(@inputs_association_paths)
              remove_instance_variable(:@inputs_association_paths)
            end

            type = type_for_declaration(...)

            if type.extends?(BuiltinTypes[:model]) && !type.extends?(BuiltinTypes[:entity])
              type = type.element_types
            end

            @inputs_type = type

            register_possible_input_errors

            @inputs_type
          end

          def add_inputs(...)
            if inputs_type
              new_type = type_for_declaration(...)
              new_declaration = TypeDeclarations::Attributes.merge(
                inputs_type.declaration_data,
                new_type.declaration_data
              )

              inputs new_declaration
            else
              inputs(...)
            end
          end

          def inputs_type
            return @inputs_type if defined?(@inputs_type)

            @inputs_type = if superclass < Foobara::Command
                             superclass.inputs_type
                           end
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

        def inputs_type
          self.class.inputs_type
        end
      end
    end
  end
end
