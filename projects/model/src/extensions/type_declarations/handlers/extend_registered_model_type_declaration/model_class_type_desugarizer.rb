module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendRegisteredModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ModelClassTypeDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            if sugary_type_declaration.is_a?(::Hash) && sugary_type_declaration.key?(:type)
              type = sugary_type_declaration[:type]
              type.is_a?(::Class) && type < Model
            end
          end

          def desugarize(hash)
            model_class = hash[:type]
            hash.merge(type: model_class.model_type.foobara_manifest_reference.to_sym)
          end

          def priority
            Priority::FIRST
          end
        end
      end
    end
  end
end
