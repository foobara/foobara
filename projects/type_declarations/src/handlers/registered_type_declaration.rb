Foobara.require_project_file("type_declarations", "type_declaration_handler")

module Foobara
  module TypeDeclarations
    module Handlers
      # TODO: we should just use the symbol instead of {type: symbol} to save space and simplify some stuff...
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        def applicable?(sugary_type_declaration)
          if sugary_type_declaration.is_a?(::Hash) && sugary_type_declaration.keys.size == 1
            sugary_type_declaration = if sugary_type_declaration.key?(:type)
                                        sugary_type_declaration[:type]
                                      elsif sugary_type_declaration.key?("type")
                                        sugary_type_declaration["type"]
                                      else
                                        return false
                                      end
          end

          if sugary_type_declaration.is_a?(::Symbol) || sugary_type_declaration.is_a?(::String)
            type_registered?(sugary_type_declaration)
          end
        end

        def priority
          Priority::HIGH
        end
      end
    end
  end
end
