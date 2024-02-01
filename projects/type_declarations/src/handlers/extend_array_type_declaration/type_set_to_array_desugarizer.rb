require_relative "array_desugarizer"

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendArrayTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class TypeSetToArrayDesugarizer < ArrayDesugarizer
          def applicable?(sugary_type_declaration)
            if sugary_type_declaration.is_a?(::Hash) && sugary_type_declaration.key?(:type)
              extra_keys = sugary_type_declaration.keys - %i[type description]

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

            strict_type_declaration
          end
        end
      end
    end
  end
end
