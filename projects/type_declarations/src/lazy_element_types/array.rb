module Foobara
  module TypeDeclarations
    module LazyElementTypes
      module Array
        module_function

        def resolve(type)
          TypeDeclarations.strict do
            element_type_declaration = type.declaration_data[:element_type_declaration]

            type.element_type = if element_type_declaration
                                  domain = type.foobara_domain
                                  domain.foobara_type_from_declaration(element_type_declaration)
                                end
          end
        end
      end
    end
  end
end
