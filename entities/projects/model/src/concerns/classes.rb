module Foobara
  class Model
    module Concerns
      module Classes
        include Concern

        module ClassMethods
          def deanonymize_class(anonymous_model_class)
            type_declaration = anonymous_model_class.model_type.declaration_data
            model_module_name = type_declaration[:model_module]

            model_module = if model_module_name
                             if Object.const_defined?(model_module_name)
                               Object.const_get(model_module_name)
                             else
                               Util.make_module_p(model_module_name)
                             end
                           end

            if model_module == GlobalDomain || !model_module
              model_module = Object
            end

            klass = type_declaration[:model_class]

            if klass && Object.const_defined?(klass) && Object.const_get(klass).is_a?(::Class)
              # should we raise an exception??
              Object.const_get(klass)
            else
              model_name = type_declaration[:name]

              existing_class = if model_module.const_defined?(model_name)
                                 model_module.const_get(model_name)
                               end

              # TODO: This is a pretty crazy situation and hacky. Should come up with a better solution.
              # Here's the situation: if models are nested, like A::B and A and A::B are modules, then
              # if A::B is imported first, A will be created as a module via make_module_p.
              # But then when we are here creating A, A is already in use incorrectly as a module.
              # We need to move A out of the way but set all of its constants on the newly created model A.
              if existing_class.is_a?(::Module) && !existing_class.is_a?(::Class)
                if existing_class.instance_variable_get(:@foobara_created_via_make_class)
                  existing_module_to_copy_over = existing_class
                  parent_mod = Util.module_for(existing_class)
                  parent_mod.send(:remove_const, Util.non_full_name(existing_class))
                else
                  # :nocov:
                  return existing_class
                  # :nocov:
                end
              end

              if existing_module_to_copy_over
                Foobara::Domain::DomainModuleExtension._copy_constants(
                  existing_module_to_copy_over, anonymous_model_class
                )
              end

              if model_name.include?("::")
                model_module_name = "#{model_module.name}::#{model_name.split("::")[..-2].join("::")}"
                model_module = Util.make_module_p(model_module_name, tag: true)
              end

              const_name = model_name.split("::").last

              model_module.const_set(const_name, anonymous_model_class)

              anonymous_model_class
            end
          end
        end
      end
    end
  end
end
