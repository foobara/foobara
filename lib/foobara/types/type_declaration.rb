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
    class TypeDeclaration < Type
      include Value::MultiProcessor
      include Concerns::TypeBuilding

      def applicable?(sugary_type_declaration_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def processors
        [*dusugarizers, *validators, type_builder_processor]
      end
    end
  end
end
