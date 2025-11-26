require_relative "../../desugarizer"
require_relative "../extend_associative_array_type_declaration"

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendTupleTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class ArrayDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration.array? && sugary_type_declaration.size > 1
          end

          def desugarize(sugary_type_declaration)
            element_type_declarations = sugary_type_declaration.declaration_data.map do |element_type_declaration|
              if element_type_declaration.is_a?(Types::Type)
                element_type_declaration.reference_or_declaration_data
              else
                declaration = TypeDeclaration.new(element_type_declaration)
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
            end

            sugary_type_declaration.declaration_data = {
              type: :tuple,
              element_type_declarations:
            }
            sugary_type_declaration.is_strict = true

            sugary_type_declaration
          end
        end
      end
    end
  end
end
