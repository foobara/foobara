module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendArrayTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        class ElementTypeDeclarationDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false unless sugary_type_declaration.hash?
            return false unless Util.all_symbolizable_keys?(sugary_type_declaration)

            sugary_type_declaration = Util.symbolize_keys(sugary_type_declaration)

            return false unless sugary_type_declaration.key?(:type) || sugary_type_declaration.key?("type")

            type_symbol = if sugary_type_declaration.key?(:type)
                            sugary_type_declaration[:type]
                          elsif sugary_type_declaration.key?("type")
                            sugary_type_declaration["type"]
                          else
                            return false
                          end

            if type_symbol.is_a?(::String)
              type_symbol = type_symbol.to_sym
            end

            if type_symbol.is_a?(::Symbol)
              if type_symbol == :array
                sugary_type_declaration.key?(:element_type_declaration) ||
                  sugary_type_declaration.key?("element_type_declaration")
              end
            end
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration.symbolize_keys!

            sugar = sugary_type_declaration[:element_type_declaration]

            strict = if sugar.is_a?(Types::Type)
                       sugar.reference_or_declaration_data
                     else
                       handler = type_declaration_handler_for(sugar)

                       declaration = TypeDeclaration.new(sugar)

                       if sugary_type_declaration.deep_duped?
                         declaration.is_deep_duped = true
                         declaration.is_duped = true
                       end

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
