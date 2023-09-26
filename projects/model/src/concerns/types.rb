module Foobara
  class Model
    module Concerns
      module Types
        include Concern

        foobara_delegate :attributes_type, to: :class

        module ClassMethods
          attr_reader :model_type

          def attributes(attributes_type_declaration)
            update_namespace

            @attributes_type_declaration = attributes_type_declaration

            set_model_type
          end

          def set_model_type
            if @attributes_type_declaration
              namespace.type_for_declaration(type_declaration(@attributes_type_declaration))

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
            model_type.element_types
          end

          def model_type=(model_type)
            if @model_type
              # :nocov:
              raise "Already set model type"
              # :nocov:
            end

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
