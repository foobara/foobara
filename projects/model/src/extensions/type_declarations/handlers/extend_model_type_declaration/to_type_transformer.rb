module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ToTypeTransformer < ExtendRegisteredTypeDeclaration::ToTypeTransformer
          # TODO: make declaration validator for model_class and model_base_class
          def target_classes(strict_type_declaration)
            model_class_name = strict_type_declaration[:model_class]

            if Object.const_defined?(model_class_name) && Object.const_get(model_class_name).is_a?(::Class)
              Object.const_get(model_class_name)
            else
              base_class_name = strict_type_declaration[:model_base_class]

              base_class = if Object.const_defined?(base_class_name)
                             Object.const_get(base_class_name)
                           else
                             foobara_domain.foobara_lookup_type!(base_class_name).target_class
                           end

              base_class.subclass(name: model_class_name)
            end
          end

          # TODO: must explode if name missing...
          def type_name(strict_type_declaration)
            strict_type_declaration[:name]
          end

          # TODO: create declaration validator for name and the others
          # TODO: seems like a smell that we don't have processors for these?
          def non_processor_keys
            [:name, :model_class, :model_base_class, :model_module, :attributes_declaration, *super]
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

                if existing_model_type
                  # :nocov:
                  raise "Did not expect #{type.declaration_data[:name]} to already exist"
                  # :nocov:
                else
                  model_class.model_type = type
                  domain = model_class.domain
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
