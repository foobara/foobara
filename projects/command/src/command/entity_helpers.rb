module Foobara
  class Command
    module EntityHelpers
      module_function

      def type_declaration_for_record_update(entity_class)
        declaration = entity_class.attributes_type.declaration_data
        # TODO: just slice out the element type declarations
        declaration = Util.deep_dup(declaration)

        declaration.delete(:defaults)
        declaration[:required] = [entity_class.primary_key_attribute]

        # expect all associations to be expressed as primary key values
        # TODO: should we have a special type for encapsulating primary keys types??
        entity_class.associations.each_pair do |data_path, type|
          if type.extends_type?(entity_class.namespace.type_for_symbol(:entity))
            target_class = type.target_class
            # TODO: do we really need declaration_data? Why cant we use the type directly?
            # TODO: make this work with the type directly for performance reasons.
            primary_key_type_declaration = target_class.primary_key_type.declaration_data
            entry = type_declaration_value_at(declaration, DataPath.new(data_path).path)
            entry.clear
            entry.merge!(primary_key_type_declaration)
          end
        end

        declaration
      end

      def type_declaration_value_at(declaration, path_parts)
        return declaration if path_parts.empty?

        path_part, *path_parts = path_parts

        declaration = case path_part
                      when :"#"
                        declaration[:element_type_declaration]
                      when Symbol, Integer
                        declaration[:element_type_declarations][path_part]
                      else
                        # :nocov:
                        raise "Bad path part #{path_part}"
                        # :nocov:
                      end

        type_declaration_value_at(declaration, path_parts)
      end
    end
  end
end
