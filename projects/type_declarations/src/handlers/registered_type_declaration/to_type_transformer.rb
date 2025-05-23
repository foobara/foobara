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

          def type_symbol(strict_type_declaration)
            strict_type_declaration[:type]
          end

          def registered_type(strict_type_declaration)
            symbol = type_symbol(strict_type_declaration)
            if TypeDeclarations.strict? || TypeDeclarations.strict_stringified?
              symbol = "::#{symbol}"
            end
            lookup_type!(symbol)
          end

          def target_classes(strict_type_declaration)
            registered_type(strict_type_declaration).target_classes
          end
        end
      end
    end
  end
end
