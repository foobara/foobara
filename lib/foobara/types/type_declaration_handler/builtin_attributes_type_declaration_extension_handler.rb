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
      class BuiltinAtomTypeDeclarationExtensionHandler < BuiltinTypeDeclaration
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

          # if there's no processors to extend the exissting type with, then we don't handle that here
          return false if strict_type_declaration.keys == [:type]

          type_symbol = strict_type_declaration[:type]
          if BuiltinTypes.registered?(type_symbol)
            type = BuiltinTypes[type_symbol]
            # Does it actually matter if it's an atom or not?
            type.is_a?(AtomType)
          end
        end
      end
    end
  end
end
