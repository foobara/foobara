module Foobara
  module Enumerated
    module Accessors
      class ValueNotAllowed < StandardError; end
      class CannotDetermineModuleAutomatically; end

      include Concern

      module ClassMethods
        def enumerated(attribute_name, values_source = nil)
          original_values_source = values_source

          if values_source.nil?
            module_name = Util.classify(attribute_name)

            values_source = begin
              Util.const_get_up_hierarchy(self, module_name)
            rescue NameError
              # :nocov:
              raise CannotDetermineModuleAutomatically,
                    "could not find a module for #{module_name}. Maybe consider passing it in explicitly."
              # :nocov:
            end
          end

          values = Values.new(values_source)

          attribute_name = attribute_name.to_sym

          # :nocov:
          unless respond_to?(:enumerated_type_metadata)
            # :nocov:
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
