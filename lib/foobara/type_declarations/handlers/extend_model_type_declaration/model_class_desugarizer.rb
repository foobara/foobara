module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ModelClassDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration[:type] == :model
          end

          def desugarize(strictish_type_declaration)
            unless strictish_type_declaration.key?(:model_class)
              model_base_class = strictish_type_declaration[:model_base_class] || Foobara::Model
              strictish_type_declaration[:model_class] = model_base_class.subclass(strictish_type_declaration)
            end

            unless strictish_type_declaration.key?(:model_base_class)
              strictish_type_declaration[:model_base_class] = strictish_type_declaration[:model_class].superclass
            end

            strictish_type_declaration
          end

          def priority
            Priority::LOW
          end
        end
      end
    end
  end
end
