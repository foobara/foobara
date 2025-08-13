module Foobara
  module TypeDeclarations
    module LazyElementTypes
      module Tuple
        module_function

        def resolve(type)
          TypeDeclarations.strict do
            element_type_declarations = type.declaration_data[:element_type_declarations]

            if element_type_declarations && !element_type_declarations.empty?
              domain = type.foobara_domain
              type.element_types = element_type_declarations.map do |element_type_declaration|
                domain.foobara_type_from_declaration(element_type_declaration)
              end
            end
          end
        end
      end
    end
  end
end
