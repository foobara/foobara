module Foobara
  module Types
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
      class BuiltinAtomTypeDeclarationExtensionHandler < RegisteredTypeDeclarationHandler
        def initialize(*args, **opts)
          super(
            *args,
            desugarizers: SymbolDesugarizer.new(true),
            to_type_transformer: ToTypeTransformer.new(true),
            **opts
          )
        end

        def applicable?(sugary_type_declaration)
          strict_type_declaration = desugarize(sugary_type_declaration)

          # if there's no processors to extend the existing type with, then we don't handle that here
          return false if strict_type_declaration.keys == [:type]

          type_symbol = strict_type_declaration[:type]
          BuiltinTypes.registered?(type_symbol)
        end
      end
    end
  end
end
