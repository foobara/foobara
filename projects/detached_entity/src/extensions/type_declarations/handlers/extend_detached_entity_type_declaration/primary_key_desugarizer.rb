module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendDetachedEntityTypeDeclaration < ExtendModelTypeDeclaration
        class PrimaryKeyDesugarizer < Desugarizer
          def applicable?(sugary_type_declaration)
            primary_key = sugary_type_declaration[:primary_key]

            primary_key.is_a?(::String)
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration[:primary_key] = sugary_type_declaration[:primary_key].to_sym
            sugary_type_declaration
          end
        end
      end
    end
  end
end
