require_relative "array_desugarizer"

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendArrayTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class TypeSetToArrayDesugarizer < ArrayDesugarizer
          def applicable?(sugary_type_declaration)
            if sugary_type_declaration.is_a?(::Hash) && sugary_type_declaration.key?(:type)
              extra_keys = sugary_type_declaration.keys - [:type, :description, :sensitive, :sensitive_exposed]

              return false if extra_keys.any?

              type = sugary_type_declaration[:type]

              if type.is_a?(::Array)
                super(type)
              end
            end
          end

          def desugarize(sugary_type_declaration)
            strict_type_declaration = super(sugary_type_declaration[:type])

            if sugary_type_declaration.key?(:description)
              strict_type_declaration[:description] = sugary_type_declaration[:description]
            end

            if sugary_type_declaration.key?(:sensitive)
              strict_type_declaration[:sensitive] = sugary_type_declaration[:sensitive]
            end

            if sugary_type_declaration.key?(:sensitive_exposed)
              strict_type_declaration[:sensitive_exposed] = sugary_type_declaration[:sensitive_exposed]
            end

            strict_type_declaration
          end
        end
      end
    end
  end
end
