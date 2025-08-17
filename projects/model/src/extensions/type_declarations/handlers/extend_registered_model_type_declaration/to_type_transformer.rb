module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendRegisteredModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        # TODO: seems like we can delete this handler entirely?
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
            # TODO: cache this on a #base_type= helper
            strict_type_declaration.type ||
              lookup_type(strict_type_declaration[:type], mode: Namespace::LookupMode::ABSOLUTE_SINGLE_NAMESPACE)
          end
        end
      end
    end
  end
end
