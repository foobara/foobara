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
      class RegisteredTypeDeclarationHandler < TypeDeclarationHandler
        def applicable?(sugary_type_declaration)
          return false unless desugarizer.applicable?(sugary_type_declaration)

          strict_type_declaration = desugarize(sugary_type_declaration)

          # we only handle case where it's a builtin type not an extension of one
          if strict_type_declaration.keys == [:type]
            type_symbol = strict_type_declaration[:type]
            type_declaration_handler_registry.registered?(type_symbol)
          end
        end
      end
    end
  end
end
