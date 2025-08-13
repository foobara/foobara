module Foobara
  module TypeDeclarations
    module LazyElementTypes
      module Attributes
        module_function

        def resolve(type)
          TypeDeclarations.strict do
            type_declarations = type.declaration_data[:element_type_declarations]

            domain = type.foobara_domain

            type.element_types = type_declarations&.transform_values do |attribute_declaration|
              domain.foobara_type_from_declaration(attribute_declaration)
            end
          end
        end
      end
    end
  end
end
