# delete this file

module Foobara
  module ModelAttributeHelpers
    module Concerns
      # TODO: This concern is retroactively designed to be mixed into any entity-like class that can hold an
      # entity-like foobara type.
      # Because we want a subclass of ActiveRecord::Base to be such a target in the case of the
      # foobara-active-record-type class, but because we can't make ActiveRecord::Base a subclass of Entity or
      # DetachedEntity, and also because it makes sense to extend such behavior to foobara model classes,
      # we will implement this as a Concern/mixin with a published expected interface and prefixed methods.
      # This also means it should live in its own project, not here in the entity project.
      # required methods:
      #
      # foobara_type
      # foobara_attributes_type
      # foobara_primary_key_attribute (nil if not an entity type)
      # foobara_primary_key_type (nil if not an entity type)
      # foobara_associations
      module AttributeHelpers
        include Foobara::Concern

        module ClassMethods
          def foobara_has_primary_key?
            respond_to?(:foobara_primary_key_attribute)
          end

          def foobara_attributes_for_update(require_primary_key: true)
            foobara_attributes_for_aggregate_update(require_primary_key:)
          end

          # TODO: we should have metadata on the entity about whether it required a primary key
          # upon creation or not instead of an option here.
          def foobara_attributes_for_create(
            includes_primary_key: false, # usually the underlying data store creates this
            include_private: true, # we usually need to initialize these values to something but not always
            include_delegates: false # usually these are already set on the passed-in objects it delegates to
          )
            if includes_primary_key && include_private
              if include_delegates || delegates.empty?
                return foobara_attributes_type
              end
            end

            declaration = foobara_attributes_type.declaration_data

            Namespace.use foobara_attributes_type.created_in_namespace do
              unless includes_primary_key
                declaration = Foobara::TypeDeclarations::Attributes.reject(declaration, foobara_primary_key_attribute)
              end

              unless include_private
                declaration = Foobara::TypeDeclarations::Attributes.reject(declaration, *private_attribute_names)
              end

              unless include_delegates
                declaration = Foobara::TypeDeclarations::Attributes.reject(declaration, *delegates.keys)
              end

              Domain.current.foobara_type_from_declaration(declaration)
            end
          end

          def foobara_attributes_for_aggregate_update(require_primary_key: true, initial: true)
            declaration = foobara_attributes_type.declaration_data
            declaration = Util.deep_dup(declaration)

            declaration.delete(:defaults)
            declaration.delete(:required)

            if initial && foobara_has_primary_key?
              if require_primary_key
                declaration[:required] = [foobara_primary_key_attribute]
              else
                declaration = TypeDeclarations::Attributes.reject(declaration, foobara_primary_key_attribute)
              end
            end

            foobara_associations.each_pair do |data_path, type|
              if type.extends?(BuiltinTypes[:entity])
                target_class = type.target_class

                set_foobara_type_declaration_value_at(
                  declaration,
                  DataPath.new(data_path).path,
                  target_class.foobara_attributes_for_aggregate_update(initial: false)
                )
              end
            end

            declaration
          end

          def foobara_attributes_for_atom_update(require_primary_key: true)
            declaration = foobara_attributes_type.declaration_data
            declaration = Util.deep_dup(declaration)

            declaration.delete(:defaults)

            if foobara_has_primary_key?
              if require_primary_key
                declaration[:required] = [foobara_primary_key_attribute]
              else
                declaration = TypeDeclarations::Attributes.reject(declaration, foobara_primary_key_attribute)
              end
            end

            # expect all associations to be expressed as primary key values
            # TODO: should we have a special type for encapsulating primary keys types??
            foobara_associations.each_pair do |data_path, type|
              if type.extends?(BuiltinTypes[:entity])
                target_class = type.target_class
                # TODO: do we really need declaration_data? Why cant we use the type directly?
                # TODO: make this work with the type directly for performance reasons.
                primary_key_type_declaration = target_class.foobara_primary_key_type.declaration_data

                set_foobara_type_declaration_value_at(
                  declaration,
                  DataPath.new(data_path).path,
                  primary_key_type_declaration
                )
              end
            end

            declaration
          end

          def foobara_attributes_for_find_by
            element_type_declarations = {}

            foobara_attributes_type.element_types.each_pair do |attribute_name, attribute_type|
              element_type_declarations[attribute_name] = attribute_type.reference_or_declaration_data
            end

            handler = Domain.global.foobara_type_builder.handler_for_class(
              TypeDeclarations::Handlers::ExtendAttributesTypeDeclaration
            )

            declaration = TypeDeclaration.new(type: :attributes, element_type_declarations:)
            declaration.is_absolutified = true
            declaration.is_duped = true

            handler.desugarize(declaration).declaration_data
          end

          private

          def set_foobara_type_declaration_value_at(declaration, path_parts, value)
            path_part, *path_parts = path_parts

            case path_part
            when :"#"
              if path_parts.empty?
                declaration[:element_type_declaration] = value
              else
                set_foobara_type_declaration_value_at(
                  declaration[:element_type_declaration],
                  path_parts,
                  value
                )
              end
            when Symbol, Integer
              if path_parts.empty?
                declaration[:element_type_declarations][path_part] = value
              else
                set_foobara_type_declaration_value_at(
                  declaration[:element_type_declarations][path_part],
                  path_parts,
                  value
                )
              end
            else
              # :nocov:
              raise "Bad path part #{path_part}"
              # :nocov:
            end
          end
        end
      end
    end
  end
end
