require "foobara/type_declarations/handlers/registered_type_declaration"

module Foobara
  module TypeDeclarations
    # This will replace Schema...
    # This is like Type
    # Instead of casters/transformers we have can_handle? and desugarizers
    # instead of validators we have declaration validators
    # process:
    #   Make sure we can handle this
    #   desugarize
    #   validate declaration value
    #   transform into Type instance
    # So... sugary type declaration value in, type out
    module Handlers
      class ExtendRegisteredTypeDeclaration < RegisteredTypeDeclaration
        def applicable?(sugary_type_declaration)
          strict_type_declaration = desugarize(sugary_type_declaration)

          return false unless strict_type_declaration.is_a?(::Hash)
          # if there's no processors to extend the existing type with, then we don't handle that here
          return false if strict_type_declaration.keys == [:type]

          super(strict_type_declaration.slice(:type))
        end

        def priority
          Priority::LOW
        end

        def type_to_extend(strict_type_declaration)
          type_symbol = strict_type_declaration[:type]
          type_for_symbol(type_symbol)
        end
      end
    end
  end
end
