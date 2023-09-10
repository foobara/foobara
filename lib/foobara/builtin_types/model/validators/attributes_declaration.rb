module Foobara
  module BuiltinTypes
    module Model
      module Validators
        class AttributesDeclaration < TypeDeclarations::Validator
          class << self
            def requires_parent_declaration_data?
              true
            end
          end

          def always_applicable?
            true
          end

          def validation_errors(model_instance)
            model_instance.validation_errors
          end

          def possible_errors
            parent_declaration_data[:model_class].possible_errors
          end
        end
      end
    end
  end
end
