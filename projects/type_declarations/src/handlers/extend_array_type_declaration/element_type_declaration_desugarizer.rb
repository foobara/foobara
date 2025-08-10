module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendArrayTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        class ElementTypeDeclarationDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false unless sugary_type_declaration.is_a?(::Hash)
            return false unless Util.all_symbolizable_keys?(sugary_type_declaration)

            sugary_type_declaration = Util.symbolize_keys(sugary_type_declaration)

            return false unless sugary_type_declaration.key?(:type)

            type_symbol = sugary_type_declaration[:type]

            type_symbol == :array && sugary_type_declaration.key?(:element_type_declaration)
          end

          def desugarize(sugary_type_declaration)
            sugar = sugary_type_declaration[:element_type_declaration]

            strict = if sugar.is_a?(Types::Type)
                       sugar.reference_or_declaration_data
                     else
                       handler = type_declaration_handler_for(sugar)
                       handler.desugarize(sugar)
                     end

            sugary_type_declaration[:element_type_declaration] = strict

            sugary_type_declaration
          end

          def priority
            Priority::LOW
          end
        end
      end
    end
  end
end
