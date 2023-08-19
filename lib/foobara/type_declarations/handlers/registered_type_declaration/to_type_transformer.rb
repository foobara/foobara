require "foobara/type_declarations/to_type_transformer"

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class ToTypeTransformer < TypeDeclarations::ToTypeTransformer
          def transform(strict_type_declaration)
            type_symbol = strict_type_declaration[:type]
            type_for_symbol(type_symbol)
          end
        end
      end
    end
  end
end
