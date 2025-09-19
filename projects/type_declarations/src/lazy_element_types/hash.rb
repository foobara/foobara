module Foobara
  module TypeDeclarations
    module LazyElementTypes
      # Using Hash instead of AssociativeArray to avoid making a symbol for it
      # (probably doesn't really matter)
      module Hash
        module_function

        def resolve(type)
          Namespace.use type.created_in_namespace do
            declaration_data = type.declaration_data

            key_type_declaration = declaration_data[:key_type_declaration]
            value_type_declaration = declaration_data[:value_type_declaration]

            type.element_types = if key_type_declaration || value_type_declaration
                                   TypeDeclarations.strict do
                                     domain = Domain.current

                                     key_declaration = if key_type_declaration
                                                         domain.foobara_type_from_declaration(key_type_declaration)
                                                       else
                                                         BuiltinTypes[:duck]
                                                       end

                                     value_declaration = if value_type_declaration
                                                           domain.foobara_type_from_declaration(value_type_declaration)
                                                         else
                                                           BuiltinTypes[:duck]
                                                         end

                                     [key_declaration, value_declaration]
                                   end
                                 end
          end
        end
      end
    end
  end
end
