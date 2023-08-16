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
      class ExtendAttributesTypeDeclarationHandler < ExtendAssociativeArrayTypeDeclarationHandler
        def applicable?(sugary_type_declaration)
          return false unless desugarizers.any? { |desugarizer| desugarizer.applicable?(sugary_type_declaration) }

          return true unless sugary_type_declaration.key?(:type)

          if sugary_type_declaration[:type] == :attributes
            sugary_type_declaration.keys.size > 1
          else
            applicable_handlers = type_declaration_handler_registry.handlers.select do |handler|
              handler != self && handler.applicable?(sugary_type_declaration)
            end

            applicable_handlers.empty?
          end
        end
      end
    end
  end
end
