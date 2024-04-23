module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ToTypeTransformer < ExtendRegisteredTypeDeclaration::ToTypeTransformer
          # TODO: make declaration validator for model_class and model_base_class
          def target_classes(strict_type_declaration)
            Object.const_get(strict_type_declaration[:model_class])
          end

          # TODO: must explode if name missing...
          def type_name(strict_type_declaration)
            strict_type_declaration[:name]
          end

          # TODO: create declaration validator for name and the others
          # TODO: seems like a smell that we don't have processors for these?
          def non_processor_keys
            [:name, :model_class, :model_base_class, :model_module, :attributes_declaration, :mutable, *super]
          end

          def process_value(...)
            super.tap do |outcome|
              if outcome.success?
                type = outcome.result

                handler = handler_for_class(ExtendAttributesTypeDeclaration)
                attributes_type_declaration = type.declaration_data[:attributes_declaration]

                type.element_types = handler.process_value!(attributes_type_declaration)

                model_class = type.target_class
                existing_model_type = model_class.model_type

                domain = model_class.domain || Domain.global

                if existing_model_type
                  if existing_model_type.declaration_data != type.declaration_data &&
                     domain.foobara_type_registered?(existing_model_type)
                    type.type_symbol = type.declaration_data[:name]
                    model_class.model_type = type
                    domain.foobara_reregister_model(model_class)
                  end
                else
                  model_class.model_type = type
                  type.type_symbol = type.declaration_data[:name]
                  model_class.description type.declaration_data[:description]
                  domain.foobara_register_model(model_class)
                end
              end
            end
          end
        end
      end
    end
  end
end
