module Foobara
  module TypeDeclarations
    module LazyElementTypes
      module Array
        # TODO: change this to class << self?

        module_function

        def resolve(type)
          Namespace.use type.created_in_namespace do
            element_type_declaration = type.declaration_data[:element_type_declaration]

            type.element_type = if element_type_declaration
                                  TypeDeclarations.strict do
                                    Domain.current.foobara_type_from_declaration(element_type_declaration)
                                  end
                                end
          end
        end
      end
    end
  end
end
