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
    class TypeDeclarationHandler < Value::Processor
      class BuiltinAtomTypeDeclarationHandler < TypeDeclarationHandler
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

          # we only handle case where it's a builtin type not an extension of one
          return false unless strict_type_declaration.keys == [:type]

          type_symbol = strict_type_declaration[:type]
          if BuiltinTypes.registered?(type_symbol)
            type = BuiltinTypes[type_symbol]
            type.is_a?(AtomType)
          end
        end
      end
    end
  end
end
