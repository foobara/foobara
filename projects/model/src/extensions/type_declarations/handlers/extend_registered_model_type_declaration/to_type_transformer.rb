module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendRegisteredModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ToTypeTransformer < ExtendRegisteredTypeDeclaration::ToTypeTransformer
          # TODO: make declaration validator for model_class and model_base_class
          def target_classes(strict_type_declaration)
            declaration_to_type(strict_type_declaration).target_classes
          end

          # TODO: must explode if name missing...
          def type_name(strict_type_declaration)
            declaration_to_type(strict_type_declaration).name
          end

          def declaration_to_type(strict_type_declaration)
            type_for_declaration(strict_type_declaration[:type])
          end

          def non_processor_keys
            [:mutable, *super]
          end
        end
      end
    end
  end
end
