module Foobara
  class Entity < DetachedEntity
    module Concerns
      module AttributeHelpers
        include Foobara::Concern

        module ClassMethods
          def attributes_for_update
            attributes_for_aggregate_update
          end

          # TODO: we should have metadata on the entity about whether it required a primary key
          # upon creation or not instead of an option here.
          def attributes_for_create(includes_primary_key: false)
            return attributes_type if includes_primary_key

            declaration = attributes_type.declaration_data
            # TODO: just slice out the element type declarations
            declaration = Util.deep_dup(declaration)

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

          def attributes_for_aggregate_update(initial = true)
            declaration = attributes_type.declaration_data
            # TODO: just slice out the element type declarations
            declaration = Util.deep_dup(declaration)

            declaration.delete(:defaults)
            declaration.delete(:required)

            if initial
              declaration[:required] = [primary_key_attribute]
            end

            associations.each_pair do |data_path, type|
              if type.extends?(BuiltinTypes[:entity])
                target_class = type.target_class

                entry = type_declaration_value_at(declaration, DataPath.new(data_path).path)
                entry.clear
                entry.merge!(target_class.attributes_for_aggregate_update(false))
              end
            end

            declaration
          end

          def attributes_for_atom_update
            declaration = attributes_type.declaration_data
            # TODO: just slice out the element type declarations
            declaration = Util.deep_dup(declaration)

            declaration.delete(:defaults)
            declaration[:required] = [primary_key_attribute]

            # expect all associations to be expressed as primary key values
            # TODO: should we have a special type for encapsulating primary keys types??
            associations.each_pair do |data_path, type|
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

          def attributes_for_find_by
            element_type_declarations = {}

            attributes_type.element_types.each_pair do |attribute_name, attribute_type|
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

          private

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
  end
end
