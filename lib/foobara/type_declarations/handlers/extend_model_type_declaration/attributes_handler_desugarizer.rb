module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendAttributesTypeDeclaration
        class AttributesHandlerDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration[:type] == :model
          end

          def desugarize(sugary_type_declaration)
            handler = Namespace.current.handler_for_class(ExtendAttributesTypeDeclaration)

            non_attributes_keys = :model_name, :model_class, :model_base_class

            attributes_type_declaration = sugary_type_declaration.except(*non_attributes_keys).merge(type: :attributes)

            attributes_type = handler.process_value!(attributes_type_declaration)

            strict_type_declaration = attributes_type.declaration_data.merge(type: :model)

            non_attributes_keys.each do |key_to_restore|
              if sugary_type_declaration.key?(key_to_restore)
                strict_type_declaration[key_to_restore] = sugary_type_declaration[key_to_restore]
              end
            end

            strict_type_declaration
          end
        end
      end
    end
  end
end
