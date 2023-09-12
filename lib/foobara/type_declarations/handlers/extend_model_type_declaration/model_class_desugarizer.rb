module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ModelClassDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration[:type] == :model
          end

          def desugarize(strictish_type_declaration)
            model_class = if strictish_type_declaration.key?(:model_class)
                            klass = strictish_type_declaration[:model_class]

                            klass.is_a?(::Class) ? klass : Object.const_get(klass)
                          else
                            model_base_class = strictish_type_declaration[:model_base_class] || Foobara::Model

                            # TODO: why not call this domain_module instead????
                            model_module = if strictish_type_declaration.key?(:model_module)
                                             mod = strictish_type_declaration[:model_module]

                                             case mod
                                             when ::Module
                                               mod
                                             when ::String, ::Symbol
                                               Object.const_get(mod)
                                             else
                                               # :nocov:
                                               raise ArgumentError,
                                                     "expected module_module to be a module or module name"
                                               # :nocov:
                                             end
                                           else
                                             Foobara::Model
                                           end

                            model_name = strictish_type_declaration[:name]

                            if model_module.const_defined?(model_name)
                              model_module.const_get(model_name)
                            else
                              model_class = model_base_class.subclass(
                                name: model_name,
                                model_module:
                              )

                              model_module.const_set(model_class.model_name, model_class)

                              model_class
                            end
                          end

            strictish_type_declaration[:model_class] = model_class.name
            model_module = Util.module_for(model_class)

            strictish_type_declaration[:model_module] = model_module&.name
            strictish_type_declaration[:model_base_class] = model_class.superclass.name

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
