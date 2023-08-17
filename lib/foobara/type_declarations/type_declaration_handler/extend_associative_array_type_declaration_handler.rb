require "foobara/type_declarations/type_declaration_handler/extend_registered_type_declaration_handler"

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
      class ExtendAssociativeArrayTypeDeclarationHandler < ExtendRegisteredTypeDeclarationHandler
        def priority
          Priority::MEDIUM
        end
      end
    end
  end
end
