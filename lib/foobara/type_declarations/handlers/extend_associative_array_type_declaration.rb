require "foobara/type_declarations/handlers/extend_registered_type_declaration"

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
    module Handlers
      class ExtendAssociativeArrayTypeDeclarationHandler < ExtendRegisteredTypeDeclarationHandler
        def priority
          Priority::MEDIUM
        end
      end
    end
  end
end
