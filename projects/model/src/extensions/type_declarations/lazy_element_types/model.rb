module Foobara
  module TypeDeclarations
    module LazyElementTypes
      module Model
        module_function

        def resolve(type)
          attributes_type_declaration = type.declaration_data[:attributes_declaration]

          type.element_types = Namespace.use(type.created_in_namespace) do
            TypeDeclarations.strict do
              handler = Domain.current.foobara_type_builder.handler_for_class(Handlers::ExtendAttributesTypeDeclaration)
              handler.process_value!(attributes_type_declaration)
            end
          end
        end
      end
    end
  end
end
