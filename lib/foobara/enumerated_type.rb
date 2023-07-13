module Foobara
  module EnumeratedType
    class BadTypeWhenAssigning < StandardError; end
    class BadTypeForConstantValue < StandardError; end
    class ValueNotAllowed < StandardError; end
    class CannotDetermineModuleAutomatically; end

    class << self
      def valid_value_type?(value)
        valid_constant_value_type?(value) || value.nil?
      end

      def valid_constant_value_type?(value)
        value.is_a?(String) || value.is_a?(Symbol)
      end
    end

    extend ActiveSupport::Concern

    class_methods do
      def enumerated(attribute_name, constants_module = nil)
        attribute_name = attribute_name.to_sym

        unless constants_module
          module_name = attribute_name.classify

          constants_module = begin
            const_get(module_name)
          rescue NameError
            raise CannotDetermineModuleAutomatically,
                  "could not find a module for #{module_name}. Maybe consider passing it in explicitly."
          end
        end

        unless respond_to?(:enumerated_type_metadata)
          class << self
            attr_accessor :enumerated_type_metadata
          end

          self.enumerated_type_metadata = {}
        end

        attr_reader attribute_name

        constants_map = {}.with_indifferent_access

        constants_module.constants.each do |constant_name|
          constant_value = constants_module.const_get(constant_name)
          unless EnumeratedType.valid_constant_value_type?(constant_value)
            raise BadTypeForConstantValue, "#{
              constant_name
            } is #{constant_value} which is a #{constant_value.class} but expected nil, String, or Symbol"
          end

          constants_map[constant_name] = constant_value && constant_value.to_sym
        end

        allowed_values = constants_map.values.to_set

        define_method "#{attribute_name}=" do |value|
          unless EnumeratedType.valid_value_type?(value)
            raise BadTypeWhenAssigning, "Expected nil, String, or Symbol, for #{
              attribute_name
            } but got #{value} which is a #{value.class}"
          end

          if value
            value = value.to_sym

            unless allowed_values.include?(value)
              raise ValueNotAllowed, "Received #{value} for #{attribute_name} but expected one of #{allowed_values}"
            end
          end

          instance_variable_set("@#{attribute_name}", value)
        end

        enumerated_type_metadata[attribute_name] = {
          constants_module:,
          allowed_values: allowed_values.to_a.sort,
          constants_map:
        }
      end
    end
  end
end
