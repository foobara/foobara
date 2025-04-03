module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ToTypeTransformer < ExtendRegisteredTypeDeclaration::ToTypeTransformer
          def existing_class_from_same_namespace_root(model_class_name)
            if Object.const_defined?(model_class_name) && Object.const_get(model_class_name).is_a?(::Class)
              existing_class = Object.const_get(model_class_name)

              # If we are operating in some other namespace tree then we don't want to use the non-anonymous class
              if Domain.current == GlobalDomain || Domain.current.foobara_root_namespace == Foobara::Namespace.global
                return existing_class
              end

              model_type = existing_class.model_type

              if model_type
                if model_type.foobara_root_namespace == Foobara::Namespace.current.foobara_root_namespace
                  # TODO: test this code path
                  # :nocov:
                  existing_class
                  # :nocov:
                end
              end
            else
              existing_type = Domain.current.foobara_lookup_type(
                model_class_name,
                mode: Namespace::LookupMode::ABSOLUTE
              )

              existing_type&.target_class
            end
          end

          # TODO: make declaration validator for model_class and model_base_class
          def target_classes(strict_type_declaration)
            model_class_name = strict_type_declaration[:model_class]

            existing_class = existing_class_from_same_namespace_root(model_class_name)

            if existing_class
              return existing_class
            end

            base_class_name = strict_type_declaration[:model_base_class]

            base_class = existing_class_from_same_namespace_root(base_class_name)
            base_class ||= lookup_type(base_class_name)&.target_class
            # If we make it here, it's a real base class like Foobara::Entity
            base_class ||= Object.const_get(base_class_name)

            base_class.subclass(name: model_class_name)
          end

          # TODO: must explode if name missing...
          def type_name(strict_type_declaration)
            strict_type_declaration[:name]
          end

          # TODO: create declaration validator for name and the others
          # TODO: seems like a smell that we don't have processors for these?
          def non_processor_keys
            [:name, :model_class, :model_base_class, :model_module, :attributes_declaration, :delegates, *super]
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

                  # this is a fairly complex way of making sure that we are getting the domain from the
                  # current namespace tree which might not be the case if we're in a command connector
                  # namespace
                  domain = model_class.domain
                  domain_name = domain.scoped_full_name
                  root_namespace = Namespace.current.foobara_root_namespace
                  domain = root_namespace.foobara_lookup_domain(domain_name)

                  type_symbol = type.declaration_data[:name]
                  type.type_symbol = type_symbol.to_sym

                  model_class.description type.declaration_data[:description]

                  if domain.foobara_type_registered?(type_symbol, mode: Namespace::LookupMode::ABSOLUTE)
                    existing_type = domain.foobara_lookup_type(type_symbol, mode: Namespace::LookupMode::ABSOLUTE)
                    domain.foobara_unregister(existing_type)
                  end

                  domain.foobara_register_model(model_class)

                  if type.declaration_data[:delegates]
                    model_class.delegate_attributes type.declaration_data[:delegates]
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
