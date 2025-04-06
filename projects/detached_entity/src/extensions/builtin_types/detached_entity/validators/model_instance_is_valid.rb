module Foobara
  module BuiltinTypes
    module DetachedEntity
      module Validators
        class ModelInstanceIsValid < Model::Validators::ModelInstanceIsValid
          # Why is this here in entity/ instead of in model/?
          def possible_errors
            return [] if parent_declaration_data == { type: expected_type_symbol }

            # TODO: we should also ask the class if it is mutable...
            mutable = parent_declaration_data.key?(:mutable) ? parent_declaration_data[:mutable] : false

            entity_class.possible_errors(mutable:)
          end

          def entity_class
            if parent_declaration_data.key?(:model_class)
              model_class_name = parent_declaration_data[:model_class]

              if Object.const_defined?(model_class_name)
                Object.const_get(parent_declaration_data[:model_class])
              else
                Namespace.current.foobara_lookup_type!(model_class_name).target_class
              end
            elsif parent_declaration_data[:type] != expected_type_symbol
              model_type = type_for_declaration(parent_declaration_data[:type])
              model_type.target_class
            else
              # :nocov:
              raise "Missing :model_class in parent_declaration_data for #{parent_declaration_data}"
              # :nocov:
            end
          end

          def expected_type_symbol
            :detached_entity
          end
        end
      end
    end
  end
end
