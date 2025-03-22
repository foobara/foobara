require_relative "typed_transformer"

module Foobara
  module TypeDeclarations
    class RemoveSensitiveValuesTransformer < TypedTransformer
      class << self
        def type_declaration(type_declaration)
          if type_declaration.is_a?(Types::Type)
            type_declaration = type_declaration.declaration_data
          end

          TypeDeclarations.remove_sensitive_types(type_declaration)
        end
      end

      def transform(_value)
        raise "subclass responsibility"
      end
    end
  end
end
