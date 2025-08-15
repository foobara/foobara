Foobara.require_project_file("type_declarations", "to_type_transformer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # TODO: seems like we have more base classes than we need
        class ToTypeTransformer < TypeDeclarations::ToTypeTransformer
          def transform(strict_type_declaration)
            registered_type(strict_type_declaration)
          end

          def registered_type(strict_type_declaration)
            type = strict_type_declaration.type

            return type if type

            type = lookup_type!(strict_type_declaration[:type], mode: Namespace::LookupMode::ABSOLUTE)

            strict_type_declaration.base_type = type
          end

          def target_classes(strict_type_declaration)
            registered_type(strict_type_declaration).target_classes
          end
        end
      end
    end
  end
end
