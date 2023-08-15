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
        def initialize(
          *args,
          type_declaration_validators: [],
          processors: [],
          desugarizers: SymbolDesugarizer.new(true),
          to_type_transformers: ToTypeTransformer.new(true),
          **opts
        )
          super(
            *Util.args_and_opts_to_args(args, opts),
            type_declaration_validators:,
            processors:,
            desugarizers:,
            to_type_transformers:
          )
        end

        def applicable?(sugary_type_declaration)
          strict_type_declaration = desugarize(sugary_type_declaration)

          # we only handle case where it's a builtin type not an extension of one
          if strict_type_declaration.keys == [:type]
            type_symbol = strict_type_declaration[:type]
            BuiltinTypes.registered?(type_symbol)
          end
        end
      end
    end
  end
end
