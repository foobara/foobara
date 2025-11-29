module Foobara
  module Domain
    module ModuleExtension
      private

      def foobara_set_types_mod_constant(types_mod, name, value)
        new_value = if value.extends?(BuiltinTypes[:model])
                      value.target_class
                    else
                      # TODO: test this path or delete it if unreachable
                      # :nocov:
                      value
                      # :nocov:
                    end

        types_mod.const_set(name, new_value)
      end
    end
  end
end
