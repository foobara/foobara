module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ModelClassDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration[:type] == expected_type_symbol
          end

          def expected_type_symbol
            :model
          end

          def default_model_base_class
            Foobara::Model
          end

          # TODO: consider splitting this up into multiple desugarizers
          def desugarize(strictish_type_declaration)
            if strictish_type_declaration.key?(:model_module)
              model_module = strictish_type_declaration[:model_module]

              strictish_type_declaration[:model_module] =
                case model_module
                when ::Module
                  model_module.name
                when ::String, nil
                  model_module
                else
                  # :nocov:
                  raise ArgumentError, "expected #{model_module} to be a module or module name"
                  # :nocov:
                end
            end

            if strictish_type_declaration.key?(:model_class)
              klass = strictish_type_declaration[:model_class]

              model_class_name = if klass && Object.const_defined?(klass) && Object.const_get(klass).is_a?(::Class)
                                   model_class = Object.const_get(klass)

                                   unless strictish_type_declaration[:model_module]
                                     model_module = Util.module_for(model_class)

                                     unless model_module == Object
                                       strictish_type_declaration[:model_module] = model_module&.name
                                     end
                                   end

                                   strictish_type_declaration[:model_base_class] ||= model_class.superclass.name

                                   model_class.name
                                 elsif klass.is_a?(::String)
                                   klass
                                 else
                                   # :nocov:
                                   raise ArgumentError, "expected #{klass} to be a class or class name"
                                   # :nocov:
                                 end

              strictish_type_declaration[:model_class] = model_class_name
            end

            model_base_class = strictish_type_declaration[:model_base_class] || default_model_base_class

            strictish_type_declaration[:model_base_class] =
              case model_base_class
              when ::Class
                model_base_class.name || model_base_class.model_name
              when ::String
                model_base_class
              else
                # :nocov:
                raise ArgumentError, "expected #{model_base_class} to be a class or class name"
                # :nocov:
              end

            if strictish_type_declaration[:name].is_a?(::Symbol)
              strictish_type_declaration[:name] = strictish_type_declaration[:name].to_s
            end

            if strictish_type_declaration[:model_module].nil?
              strictish_type_declaration.delete(:model_module)
            end

            strictish_type_declaration[:model_class] ||= [
              *strictish_type_declaration[:model_module],
              strictish_type_declaration[:name]
            ].join("::")

            strictish_type_declaration
          end

          def priority
            Priority::LOW
          end
        end
      end
    end
  end
end
