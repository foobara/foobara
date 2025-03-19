require_relative "../sensitive_type_remover"

module Foobara
  module TypeDeclarations
    module SensitiveTypeRemovers
      class Attributes < SensitiveTypeRemover
        def transform(strict_type_declaration)
          to_change = {}
          to_remove = []

          strict_type_declaration[:element_type_declarations].each_pair do |attribute_name, attribute_declaration|
            if attribute_declaration[:sensitive]
              to_remove << attribute_name
            else
              new_declaration = remove_sensitive_types(attribute_declaration)

              if new_declaration != attribute_declaration
                to_change[attribute_name] = new_declaration
              end
            end
          end

          if to_change.empty? && to_remove.empty?
            strict_type_declaration
          else
            new_declaration = if to_remove.empty?
                                strict_type_declaration
                              else
                                TypeDeclarations::Attributes.reject(strict_type_declaration, *to_remove)
                              end

            unless to_change.empty?
              new_elements = new_declaration[:element_type_declarations].merge(to_change)
              new_declaration = new_declaration.merge(element_type_declarations: new_elements)
            end

            new_declaration
          end
        end
      end
    end
  end
end
