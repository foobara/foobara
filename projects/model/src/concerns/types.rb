module Foobara
  class Model
    module Concerns
      module Types
        include Concern

        foobara_delegate :attributes_type, to: :class

        module ClassMethods
          attr_reader :model_type
          attr_writer :attributes_type

          def mutable(*args)
            args_size = args.size
            case args.size
            when 0
              if defined?(@mutable_override)
                @mutable_override
              else
                type = model_type

                if type
                  if type.declaration_data.key?(:mutable)
                    type.declaration_data[:mutable]
                  end
                end
              end
            when 1
              @mutable_override = args.first
              set_model_type
            else
              # :nocov:
              raise ArgumentError, "Expected 0 or 1 arguments but got #{args_size}"
              # :nocov:
            end
          end

          def attributes(*args, **opts, &)
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
            return if abstract?

            if attributes_type
              declaration = type_declaration(attributes_type.declaration_data)

              if model_type
                unless Foobara::TypeDeclarations.declarations_equal?(declaration, model_type.declaration_data)
                  domain.foobara_unregister(model_type)
                  self.model_type = nil
                  domain.foobara_type_from_declaration(declaration)
                end
              else
                domain.foobara_type_from_declaration(declaration)
              end
            end
          end

          def foobara_type
            model_type
          end

          def type_declaration(attributes_declaration)
            if name
              model_base_class = superclass.name
              model_class = name

              if name.start_with?(closest_namespace_module.name)
                model_module_name = closest_namespace_module.name
                model_name = name.gsub(/^#{closest_namespace_module.name}::/, "")
              else
                model_module_name = nil
                model_name = name
              end
            else
              model_module_name = model_type.declaration_data[:model_module]
              model_class = model_type.declaration_data[:model_class]
              model_name = model_type.scoped_name
              model_base_class = superclass.name || superclass.model_type.scoped_full_name
            end

            Util.remove_blank(
              type: :model,
              name: model_name,
              model_module: model_module_name,
              model_class:,
              model_base_class:,
              attributes_declaration:,
              description:,
              _desugarized: { type_absolutified: true },
              mutable:,
              delegates:
            )
          end

          def foobara_attributes_type
            return @attributes_type if @attributes_type

            @attributes_type = if model_type
                                 model_type.element_types
                               elsif ancestors.find { |ancestor| ancestor < Model }
                                 superclass.attributes_type
                               end
          end

          alias attributes_type foobara_attributes_type

          def model_type=(model_type)
            @model_type = model_type

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

          def delegates
            @delegates ||= {}
          end

          def delegate_attributes(delegates)
            delegates.each_pair do |attribute_name, delegate_info|
              delegate_attribute(attribute_name, delegate_info[:data_path], writer: delegate_info[:writer])
            end
          end

          def delegate_attribute(attribute_name, data_path, writer: false)
            data_path = DataPath.new(data_path)

            delegate_manifest = { data_path: data_path.to_s }

            if writer
              delegate_manifest[:writer] = true
            end

            delegates[attribute_name] = delegate_manifest

            define_method attribute_name do
              data_path.value_at(self)
            end

            if writer
              define_method "#{attribute_name}=" do |value|
                data_path.set_value_at(self, value)
              end
            end

            set_model_type
          end
        end
      end
    end
  end
end
