module Foobara
  class Command
    module Concerns
      module InputsType
        include Concern

        module ClassMethods
          def inputs(inputs_type_declaration)
            @inputs_type = if inputs_type_declaration.is_a?(Class) && inputs_type_declaration < Entity
                             # TODO: Allowing this seems risky and complicated. reconsider this.
                             entity_class = inputs_type_declaration
                             depends_on_entities << entity_class

                             method_name = Util.underscore(entity_class.entity_name)

                             define_method method_name do
                               var_name = "@#{method_name}"
                               if instance_variable_defined?(var_name)
                                 instance_variable_get(var_name)
                               else
                                 instance_variable_set(var_name, entity_class.create(inputs))
                               end
                             end

                             entity_class.attributes_type
                           else
                             type_for_declaration(inputs_type_declaration)
                           end

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

        foobara_delegate :inputs_type, :raw_inputs_type_declaration, to: :class
      end
    end
  end
end
