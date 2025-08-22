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

          def attributes(...)
            private, attributes_type_declaration = extract_private_from_attributes_declaration(...)

            new_type = domain.foobara_type_from_declaration(attributes_type_declaration)
            existing_type = attributes_type

            if existing_type
              declaration = TypeDeclarations::Attributes.merge(
                existing_type.declaration_data,
                new_type.declaration_data
              )

              new_type = domain.foobara_type_from_declaration(declaration)
            end

            self.attributes_type = new_type
            private_attributes(private)

            set_model_type
          end

          def set_model_type
            return if abstract?

            if attributes_type
              declaration = type_declaration(attributes_type.declaration_data)

              if model_type
                unless Foobara::TypeDeclarations.declarations_equal?(declaration.declaration_data,
                                                                     model_type.declaration_data)

                  type_domain = domain
                  self.model_type = nil

                  type_domain.foobara_type_from_declaration(declaration)
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
            if model_type
              model_module_name = model_type.declaration_data[:model_module]
              model_class = model_type.declaration_data[:model_class]
              model_name = model_type.scoped_name
              model_base_class = superclass.name || superclass.model_type.scoped_full_name
            else
              model_base_class = superclass.name || superclass.full_model_name
              model_class = name || full_model_name

              if model_class.start_with?(closest_namespace_module.name)
                model_module_name = closest_namespace_module.name
                model_name = model_class.gsub(/^#{closest_namespace_module.name}::/, "")
              else
                model_module_name = nil
                model_name = model_class
              end
            end

            type_declaration = TypeDeclaration.new(
              Util.remove_blank(
                type: :model,
                name: model_name,
                model_module: model_module_name,
                model_class:,
                model_base_class:,
                attributes_declaration:,
                description:,
                mutable:,
                delegates:,
                private: private_attribute_names
              )
            )

            type_declaration.is_absolutified = true
            type_declaration.is_duped = true

            type_declaration
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

            return if model_type.nil?

            private = model_type.declaration_data[:private]

            attributes_type.element_types.each_key do |attribute_name|
              if delegates.key?(attribute_name)
                next
              end

              define_method attribute_name do
                read_attribute(attribute_name)
              end

              # TODO: let's cache validation_errors and clobber caches when updating this for performance reasons
              define_method "#{attribute_name}=" do |value|
                write_attribute(attribute_name, value)
              end

              if private&.include?(attribute_name)
                private attribute_name
                private "#{attribute_name}="
              end
            end
          end

          def foobara_delegates
            @foobara_delegates ||= {}
          end

          def has_delegated_attributes?
            !delegates.empty?
          end

          def foobara_private_attribute_names
            @foobara_private_attribute_names ||= []
          end

          def private_attributes(attribute_names)
            attribute_names.each do |attribute_name|
              private_attribute attribute_name
            end
          end

          def private_attribute(attribute_name)
            @foobara_private_attribute_names = private_attribute_names | [attribute_name]

            set_model_type
          end

          def delegate_attributes(delegates)
            delegates.each_pair do |attribute_name, delegate_info|
              data_path = DataPath.for(delegate_info[:data_path])
              delegate_attribute(attribute_name, data_path, writer: delegate_info[:writer])
            end
          end

          def delegate_attribute(attribute_name, data_path, writer: false)
            if data_path.is_a?(::Symbol) || data_path.is_a?(::String)
              data_path = [data_path, attribute_name]
            end

            data_path = DataPath.for(data_path)

            delegate_manifest = { data_path: data_path.to_s }

            if writer
              delegate_manifest[:writer] = true
            end

            delegates[attribute_name] = delegate_manifest

            delegated_type_declaration = model_type.type_at_path(data_path).reference_or_declaration_data
            attributes(type: :attributes, element_type_declarations: { attribute_name => delegated_type_declaration })

            define_method attribute_name do
              data_path.value_at(self)
            end

            if writer
              define_method "#{attribute_name}=" do |value|
                data_path.set_value_at(self, value)
              end
            else
              method = :"#{attribute_name}="

              if instance_methods.include?(method)
                # TODO: test this code path
                # :nocov:
                remove_method method
                # :nocov:
              end
            end

            set_model_type
          end

          private

          def extract_private_from_attributes_declaration(...)
            private = []
            attributes_type_declaration = TypeDeclarations.args_to_type_declaration(...)

            if attributes_type_declaration.hash? || attributes_type_declaration.proc?
              handler = domain.foobara_type_builder.handler_for_class(
                TypeDeclarations::Handlers::ExtendAttributesTypeDeclaration
              )
              attributes_type_declaration = Namespace.use domain do
                handler.desugarize(attributes_type_declaration.clone)
              end

              element_type_declarations = attributes_type_declaration[:element_type_declarations]

              element_type_declarations.each_pair do |attribute_name, attribute_type_declaration|
                next if attribute_type_declaration.is_a?(::Symbol)

                is_private = attribute_type_declaration.delete(:private)

                if is_private
                  if attribute_type_declaration.keys.size == 1
                    element_type_declarations[attribute_name] = attribute_type_declaration[:type]
                  end

                  private |= [attribute_name]
                end
              end
            end

            [private, attributes_type_declaration]
          end
        end
      end
    end
  end
end
