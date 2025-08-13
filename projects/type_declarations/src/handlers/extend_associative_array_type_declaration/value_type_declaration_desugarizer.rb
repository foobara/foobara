require_relative "../extend_registered_type_declaration"
require_relative "../../desugarizer"

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAssociativeArrayTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ValueTypeDeclarationDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false if sugary_type_declaration.strict?
            return false unless sugary_type_declaration.hash?
            return false unless sugary_type_declaration.all_symbolizable_keys?

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
              if type_symbol == :associative_array
                sugary_type_declaration.key?(:value_type_declaration) ||
                  sugary_type_declaration.key?("value_type_declaration")
              end
            end
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration.symbolize_keys!

            sugar = sugary_type_declaration[:value_type_declaration]

            strict = if sugar.is_a?(Types::Type)
                       sugar.reference_or_declaration_data
                     else
                       declaration = sugary_type_declaration.clone_from_part(sugar)

                       if sugary_type_declaration.deep_duped?
                         declaration.is_deep_duped = true
                         declaration.is_duped = true
                       end

                       handler = type_declaration_handler_for(declaration)
                       handler.desugarize(declaration).declaration_data
                     end

            sugary_type_declaration[:value_type_declaration] = strict

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
