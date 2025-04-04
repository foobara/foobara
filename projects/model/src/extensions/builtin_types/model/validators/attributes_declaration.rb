module Foobara
  module BuiltinTypes
    module Model
      module Validators
        class ModelInstanceIsValid < TypeDeclarations::Processor
          class << self
            def requires_parent_declaration_data?
              true
            end

            def requires_declaration_data?
              false
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
              model_class = if Object.const_defined?(model_class_name)
                              Object.const_get(model_class_name)
                            else
                              Namespace.current.foobara_lookup_type!(model_class_name).target_class
                            end

              model_class.possible_errors
            else
              super
            end
          end
        end
      end
    end
  end
end
