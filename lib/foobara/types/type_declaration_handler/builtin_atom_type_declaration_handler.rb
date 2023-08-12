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
    # TODO: maybe change name to TypeDeclarationProcessor?? That frees up
    # the type declaration value to be known as a type declaration and makes
    # passing it ot the Type maybe a little less awkward.
    class TypeDeclarationHandler < Value::Processor
      class BuiltinAtomTypeDeclarationHandler < TypeDeclarationHandler
        def applicable?(sugary_type_declaration)
          type_symbol = type_declaration_to_type_symbol(sugary_type_declaration)

          type_symbol && BuiltinTypes.registered?(type_symbol)
        end

        def desugarizers
          @desugarizers ||= [SymbolDesugarizer.instance]
        end

        def process(sugary_type_declaration)
          type_symbol = type_declaration_to_type_symbol(sugary_type_declaration)

          Outcome.success(BuiltinTypes[type_symbol])
        end

        private

        def type_declaration_to_type_symbol(sugary_type_declaration)
          if sugary_type_declaration.is_a?(Hash)
            sugary_type_declaration[:type]
          elsif sugary_type_declaration.is_a?(Symbol)
            sugary_type_declaration
          end
        end
      end
    end
  end
end
