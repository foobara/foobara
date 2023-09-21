module Foobara
  module TypeDeclarations
    class TypeDeclarationValidator < Value::Validator
      include WithRegistries

      class << self
        def manifest
          # :nocov:
          super.merge(processor_type: :type_declaration_validator)
          # :nocov:
        end
      end

      def always_applicable?
        true
      end
    end
  end
end
