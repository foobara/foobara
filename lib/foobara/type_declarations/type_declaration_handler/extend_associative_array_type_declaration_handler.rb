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
      class ExtendAssociativeArrayTypeDeclarationHandler < RegisteredTypeDeclarationHandler
      end
    end
  end
end
