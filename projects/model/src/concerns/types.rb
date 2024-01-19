module Foobara
  class Model
    module Concerns
      module Types
        include Concern

        foobara_delegate :attributes_type, to: :class

        module ClassMethods
          attr_reader :model_type
          attr_writer :attributes_type

          def attributes(additional_attributes_type_declaration)
            update_namespace

            handler = domain.foobara_type_builder.handler_for_class(
              Foobara::TypeDeclarations::Handlers::ExtendAttributesTypeDeclaration
            )

            new_type = handler.type_for_declaration(additional_attributes_type_declaration)

            existing_type = attributes_type

            if existing_type
              # TODO: make a first-class way to update/merge/union types!!
              element_type_declarations = {}
              required = []
              defaults = {}

              [existing_type, new_type].each do |type|
                element_type_declarations.merge!(type.declaration_data[:element_type_declarations])
                type_defaults = type.declaration_data[:defaults]
                type_required = type.declaration_data[:required]

                if type_defaults && !type_defaults.empty?
                  defaults.merge!(type_defaults)
                end

                if type_required && !type_required.empty?
                  required += type_required
                end
              end

              new_type = domain.foobara_type_from_declaration(
                type: :attributes,
                element_type_declarations:,
                required:,
                defaults:
              )
            end

            self.attributes_type = new_type

            set_model_type
          end

          def set_model_type
            update_namespace

            return if abstract?

            if attributes_type
              declaration = type_declaration(attributes_type.declaration_data)

              domain.foobara_type_from_declaration(declaration)

              unless @model_type
                # :nocov:
                raise "Expected model type to automatically be registered"
                # :nocov:
              end
            end
          end

          def type_declaration(attributes_declaration)
            {
              type: :model,
              name: model_name,
              model_class: self,
              model_base_class: superclass,
              attributes_declaration:
            }
          end

          def attributes_type
            return @attributes_type if @attributes_type

            @attributes_type = if model_type
                                 model_type.element_types
                               elsif ancestors.find { |ancestor| ancestor < Model }
                                 superclass.attributes_type
                               end
          end

          def model_type=(model_type)
            @model_type = model_type

            update_namespace

            attributes_type.element_types.each_key do |attribute_name|
              define_method attribute_name do
                read_attribute(attribute_name)
              end

              # TODO: let's cache validation_errors and clobber caches when updating this for performance reasons
              define_method "#{attribute_name}=" do |value|
                write_attribute(attribute_name, value)
              end
            end
          end
        end
      end
    end
  end
end
