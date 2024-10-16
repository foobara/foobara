module Foobara
  class Command
    module EntityHelpers
      module_function

      # Just for convenience
      def attributes_for_update(entity_class)
        type_declaration_for_record_aggregate_update(entity_class)
      end

      # TODO: we should have metadata on the entity about whether it required a primary key
      # upon creation or not instead of an option here.
      def attributes_for_create(entity_class, includes_primary_key: false)
        attributes_type = entity_class.attributes_type

        return attributes_type if includes_primary_key

        declaration = attributes_type.declaration_data
        # TODO: just slice out the element type declarations
        declaration = Util.deep_dup(declaration)

        primary_key_attribute = entity_class.primary_key_attribute

        if declaration.key?(:required) && declaration[:required].include?(primary_key_attribute)
          declaration[:required].delete(primary_key_attribute)
        end

        if declaration.key?(:defaults) && declaration[:defaults].include?(primary_key_attribute)
          declaration[:defaults].delete(primary_key_attribute)
        end

        if declaration.key?(:element_type_declarations)
          if declaration[:element_type_declarations].key?(primary_key_attribute)
            declaration[:element_type_declarations].delete(primary_key_attribute)
          end
        end

        handler = Domain.global.foobara_type_builder.handler_for_class(
          TypeDeclarations::Handlers::ExtendAttributesTypeDeclaration
        )

        handler.desugarize(declaration)
      end

      def type_declaration_for_record_aggregate_update(entity_class, initial = true)
        declaration = entity_class.attributes_type.declaration_data
        # TODO: just slice out the element type declarations
        declaration = Util.deep_dup(declaration)

        declaration.delete(:defaults)
        declaration.delete(:required)

        if initial
          declaration[:required] = [entity_class.primary_key_attribute]
        end

        entity_class.associations.each_pair do |data_path, type|
          if type.extends?(BuiltinTypes[:entity])
            target_class = type.target_class

            entry = type_declaration_value_at(declaration, DataPath.new(data_path).path)
            entry.clear
            entry.merge!(type_declaration_for_record_aggregate_update(target_class, false))
          end
        end

        declaration
      end

      def type_declaration_for_record_atom_update(entity_class)
        declaration = entity_class.attributes_type.declaration_data
        # TODO: just slice out the element type declarations
        declaration = Util.deep_dup(declaration)

        declaration.delete(:defaults)
        declaration[:required] = [entity_class.primary_key_attribute]

        # expect all associations to be expressed as primary key values
        # TODO: should we have a special type for encapsulating primary keys types??
        entity_class.associations.each_pair do |data_path, type|
          if type.extends?(BuiltinTypes[:entity])
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

      def type_declaration_for_find_by(entity_class)
        element_type_declarations = {}

        entity_class.attributes_type.element_types.each_pair do |attribute_name, attribute_type|
          element_type_declarations[attribute_name] = attribute_type.reference_or_declaration_data
        end

        handler = Domain.global.foobara_type_builder.handler_for_class(
          TypeDeclarations::Handlers::ExtendAttributesTypeDeclaration
        )

        handler.desugarize(
          type: "::attributes",
          element_type_declarations:
        )
      end

      def update_aggregate(object, value, type = object.class.model_type)
        return value if object.nil?

        if type.extends?(BuiltinTypes[:model])
          element_types = type.element_types.element_types

          value.each_pair do |attribute_name, new_value|
            current_value = object.read_attribute(attribute_name)

            attribute_type = element_types[attribute_name]

            updated_value = update_aggregate(current_value, new_value, attribute_type)

            object.write_attribute(attribute_name, updated_value)
          end

          object
        elsif type.extends?(BuiltinTypes[:attributes])
          element_types = type.element_types

          object = object.dup
          object ||= {}

          value.each_pair do |attribute_name, new_value|
            current_value = object[attribute_name]
            attribute_type = element_types[attribute_name]

            updated_value = update_aggregate(current_value, new_value, attribute_type)

            object[attribute_name] = updated_value
          end

          object
        elsif type.extends?(BuiltinTypes[:tuple])
          # :nocov:
          raise "Tuple not yet supported"
        # :nocov:
        elsif type.extends?(BuiltinTypes[:associative_array])
          # :nocov:
          raise "Associated array not yet supported"
        # :nocov:
        elsif type.extends?(BuiltinTypes[:array])
          element_type = type.element_type

          value.map.with_index do |element, index|
            update_aggregate(object[index], element, element_type)
          end
        else
          value
        end
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
