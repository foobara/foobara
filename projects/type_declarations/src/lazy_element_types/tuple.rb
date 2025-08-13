module Foobara
  module TypeDeclarations
    module LazyElementTypes
      module Tuple
        module_function

        def resolve(type)
          element_type_declarations = type.declaration_data[:element_type_declarations]

          type.element_types = if element_type_declarations
                                 if element_type_declarations.empty?
                                   []
                                 else
                                   Namespace.use(type.created_in_namespace) do
                                     TypeDeclarations.strict do
                                       domain = Domain.current

                                       element_type_declarations.map do |element_type_declaration|
                                         domain.foobara_type_from_declaration(element_type_declaration)
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
