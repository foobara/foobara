module Foobara
  module TypeDeclarations
    class TypeDeclarationValidator < Value::Validator
      include WithRegistries

      class << self
        def foobara_manifest(to_include: Set.new)
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
