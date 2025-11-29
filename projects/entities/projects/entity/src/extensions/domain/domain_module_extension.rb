module Foobara
  module Domain
    module DomainModuleExtension
      module ClassMethods
        attr_reader :foobara_default_entity_base

        def foobara_set_entity_base(*, name: nil, table_prefix: nil)
          name ||= Util.underscore(scoped_full_name).gsub("::", "_")
          base = Persistence.register_base(*, name:, table_prefix:)
          @foobara_default_entity_base = base
        end

        def foobara_register_and_deanonymize_entity(name, *, &)
          entity_class = foobara_register_entity(name, *, &)
          Foobara::Model.deanonymize_class(entity_class)
        end

        # TODO: kill this off
        def foobara_register_entity(name, *args, &block)
          # TODO: introduce a Namespace#scope method to simplify this a bit
          Foobara::Namespace.use self do
            if block
              args = [
                TypeDeclarations::Dsl::Attributes.to_declaration(&block).declaration_data,
                *args
              ]
            end

            attributes_type_declaration, *args = args

            model_base_class, description = case args.size
                                            when 0
                                              []
                                            when 1, 2
                                              arg, other = args

                                              if args.first.is_a?(::String)
                                                [other, arg]
                                              else
                                                args
                                              end
                                            else
                                              # :nocov:
                                              raise ArgumentError, "Too many arguments"
                                              # :nocov:
                                            end

            if model_base_class
              attributes_type_declaration = TypeDeclarations::Attributes.merge(
                model_base_class.attributes_type.declaration_data,
                attributes_type_declaration
              )
            end

            handler = foobara_type_builder.handler_for_class(
              Foobara::TypeDeclarations::Handlers::ExtendAttributesTypeDeclaration
            )

            attributes_type = handler.type_for_declaration(attributes_type_declaration)

            # TODO: reuse the model_base_class primary key if it has one...
            primary_key = attributes_type.element_types.keys.first

            model_module = unless scoped_full_path.empty?
                             scoped_full_name
                           end

            declaration = TypeDeclaration.new(
              Util.remove_blank(
                type: :entity,
                name:,
                model_base_class:,
                model_module:,
                attributes_declaration: attributes_type_declaration,
                primary_key:,
                description:
              )
            )

            declaration.is_absolutified = true
            declaration.is_duped = true

            entity_type = foobara_type_builder.type_for_declaration(declaration)

            entity_type.target_class
          end
        end

        def foobara_register_and_deanonymize_entities(entity_names_to_attributes)
          entities = []

          entity_names_to_attributes.each_pair do |entity_name, attributes_declaration|
            entities << foobara_register_and_deanonymize_entity(entity_name, attributes_declaration)
          end

          entities
        end

        def foobara_register_entities(entity_names_to_attributes)
          entities = []

          entity_names_to_attributes.each_pair do |entity_name, attributes_type_declaration|
            entities << foobara_register_entity(entity_name, attributes_type_declaration)
          end

          entities
        end
      end
    end
  end
end
