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
    class TypeDeclarationHandler < Value::Processor::Pipeline
      class ExtendRegisteredTypeDeclarationHandler < RegisteredTypeDeclarationHandler
        def applicable?(sugary_type_declaration)
          strict_type_declaration = desugarize(sugary_type_declaration)

          # if there's no processors to extend the existing type with, then we don't handle that here
          return false if strict_type_declaration.keys == [:type]

          type_symbol = strict_type_declaration[:type]
          type_registry.registered?(type_symbol)
        end

        def type_to_extend(strict_type_declaration)
          type_symbol = strict_type_declaration[:type]
          type_registry[type_symbol]
        end
      end
    end
  end
end
