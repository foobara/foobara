module Foobara
  class Model
    module Concerns
      module Types
        include Concern

        foobara_delegate :attributes_type, to: :class

        module ClassMethods
          attr_reader :model_type
          attr_writer :attributes_type

          def attributes(*args, **opts, &)
            update_namespace

            new_type = domain.foobara_type_from_declaration(*args, **opts, &)

            unless new_type.extends?(BuiltinTypes[:attributes])
              # :nocov:
              raise ArgumentError, "Expected #{args} #{opts} to extend :attributes " \
                                   "but instead it resulted in: #{new_type.declaration_data}"
              # :nocov:
            end

            existing_type = attributes_type

            if existing_type
              declaration = TypeDeclarations::Attributes.merge(
                existing_type.declaration_data,
                new_type.declaration_data
              )

              new_type = domain.foobara_type_from_declaration(declaration)
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
            if name.start_with?(domain.name)
              model_module_name = domain.name
              model_name = name.gsub(/^#{domain.name}::/, "")
            else
              model_module_name = Util.parent_module_name_for(name)
              model_name = Util.non_full_name(self)
            end

            Util.remove_blank(
              type: :model,
              name: model_name,
              model_module: model_module_name,
              model_class: self,
              model_base_class: superclass,
              attributes_declaration:,
              description:,
              _desugarized: { type_absolutified: true }
            )
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
