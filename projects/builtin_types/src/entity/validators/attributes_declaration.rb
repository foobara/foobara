Foobara.require_file("builtin_types", "model/validators/attributes_declaration")

module Foobara
  module BuiltinTypes
    module Entity
      module Validators
        class AttributesDeclaration < Foobara::BuiltinTypes::Model::Validators::AttributesDeclaration
          class << self
            def requires_parent_declaration_data?
              true
            end
          end

          def always_applicable?
            true
          end

          def process_value(model_instance)
            Outcome.new(result: model_instance, errors: model_instance.validation_errors)
          end

          def possible_errors
            model_class_name = parent_declaration_data[:model_class]

            if model_class_name
              Object.const_get(model_class_name).possible_errors
            else
              super
            end
          end
        end
      end
    end
  end
end
