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
        attr_accessor :supported_processors_to_apply

        def initialize(
          *args,
          desugarizers: SymbolDesugarizer.new(true),
          type_declaration_validators: [],
          to_type_transformer: ToTypeTransformer.new(true),
          processors: [],
          **supported_processors_to_apply
        )
          self.supported_processors_to_apply = supported_processors_to_apply

          super(
            *args, # TODO: would we like to consider the processors to apply as part of the declaration_data?
            desugarizers:,
            to_type_transformer:,
            type_declaration_validators:,
            processors:
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
