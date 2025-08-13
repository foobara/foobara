module Foobara
  module TypeDeclarations
    module LazyElementTypes
      # Using Hash instead of AssociativeArray to avoid making a symbol for it
      # (probably doesn't really matter)
      module Hash
        module_function

        def resolve(type)
          declaration_data = type.declaration_data

          key_type_declaration = declaration_data[:key_type_declaration]
          value_type_declaration = declaration_data[:value_type_declaration]

          type.element_types = if key_type_declaration || value_type_declaration
                                 TypeDeclarations.strict do
                                   domain = Domain.current

                                   [
                                     domain.foobara_type_from_declaration(key_type_declaration || :duck),
                                     domain.foobara_type_from_declaration(value_type_declaration || :duck)
                                   ]
                                 end
                               end
        end
      end
    end
  end
end
