module Foobara
  module Enumerated
    module Accessors
      class ValueNotAllowed < StandardError; end
      class CannotDetermineModuleAutomatically; end

      class << self
        def const_get_up_hierarchy(mod, name)
          mod.const_get(name)
        rescue NameError
          raise if mod == Object

          mod_name = mod.name

          mod = if mod_name
                  Foobara::Util.module_for(mod)
                else
                  Object
                end

          const_get_up_hierarchy(mod, name)
        end
      end

      extend ActiveSupport::Concern

      class_methods do
        def enumerated(attribute_name, values_source = nil)
          original_values_source = values_source

          if values_source.nil?
            module_name = attribute_name.to_s.camelize

            values_source = begin
              Accessors.const_get_up_hierarchy(self, module_name)
            rescue NameError
              raise CannotDetermineModuleAutomatically,
                    "could not find a module for #{module_name}. Maybe consider passing it in explicitly."
            end
          end

          values = Values.new(values_source)

          attribute_name = attribute_name.to_sym

          unless respond_to?(:enumerated_type_metadata)
            class << self
              attr_accessor :enumerated_type_metadata
            end

            self.enumerated_type_metadata = {}
          end

          attr_reader attribute_name

          define_method "#{attribute_name}=" do |value|
            value = Values.normalize_value(value)

            if !value.nil? && !values.all_values.include?(value)
              raise ValueNotAllowed, "Received #{value} for #{attribute_name} but expected one of #{values.all_values}"
            end

            instance_variable_set("@#{attribute_name}", value)
          end

          enumerated_type_metadata[attribute_name] = {
            original_values_source:,
            values_source:,
            values:
          }
        end
      end
    end
  end
end
