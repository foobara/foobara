require "foobara/type_declarations/handlers/registered_type_declaration/to_type_transformer"
require "foobara/type_declarations/handlers/extend_associative_array_type_declaration"

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendAttributesTypeDeclaration
        class ToTypeTransformer < ExtendAttributesTypeDeclaration::ToTypeTransformer
          def target_classes(strict_type_declaration)
            model_class = strict_type_declaration[:model_class]

            return model_class if model_class

            model_base_class = strict_type_declaration[:model_base_class] || Foobara::Model

            model_base_class.subclass(strict_type_declaration)
          end

          def type_name(strict_type_declaration)
            strict_type_declaration[:model_name]
          end

          # TODO: create declaration validator for model_name and the others
          def non_processor_keys
            %i[type model_name model_class model_base_class]
          end
        end
      end
    end
  end
end
