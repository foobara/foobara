module Foobara
  module TypeDeclarations
    module LazyElementTypes
      module Attributes
        module_function

        def resolve(type)
          type_declarations = type.declaration_data[:element_type_declarations]

          type.element_types = if type_declarations
                                 if type_declarations.empty?
                                   {}
                                 else
                                   Namespace.use(type.created_in_namespace) do
                                     TypeDeclarations.strict do
                                       domain = Domain.current

                                       type_declarations.transform_values do |attribute_declaration|
                                         domain.foobara_type_from_declaration(attribute_declaration)
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
