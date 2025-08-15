module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendArrayTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        class ElementTypeDeclarationDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false if sugary_type_declaration.strict?
            return false unless sugary_type_declaration.hash?
            return false unless sugary_type_declaration.all_symbolizable_keys?

            type_symbol = sugary_type_declaration[:type]

            type_symbol.is_a?(::Symbol) && type_symbol == :array &&
              sugary_type_declaration.key?(:element_type_declaration)
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration.symbolize_keys!

            sugar = sugary_type_declaration[:element_type_declaration]

            strict = if sugar.is_a?(Types::Type)
                       sugar.reference_or_declaration_data
                     else
                       declaration = sugary_type_declaration.clone_from_part(sugar)

                       if sugary_type_declaration.deep_duped?
                         # TODO: probably not worth directly testing this path
                         # :nocov:
                         declaration.is_deep_duped = true
                         declaration.is_duped = true
                         # :nocov:
                       end

                       handler = type_declaration_handler_for(declaration)
                       handler.desugarize(declaration).declaration_data
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
