module Foobara
  module Types
    class Type < Value::Processor::Pipeline
      module Concerns
        module Reflection
          include Concern

          # as soon as we hit a registered type, don't go further down that path
          def types_depended_on(result = nil)
            start = result.nil?
            result ||= Set.new
            return if result.include?(self)

            result << self

            return if !start && registered?

            to_process = [*base_type, *element_type, *possible_errors.map(&:error_class)]

            if element_types
              to_process += case element_types
                            when Type
                              [element_types]
                            when ::Hash
                              element_types.values.select { |value| value.is_a?(Type) }
                            when ::Array
                              element_types
                            else
                              # :nocov:
                              raise "Not sure how to find dependent types for #{element_types}"
                              # :nocov:
                            end
            end

            to_process.each do |type|
              type.types_depended_on(result)
            end

            if start
              result = result.select { |type| type.registered? && type != self }.to_set
            end

            result
          end

          def deep_types_depended_on
            result = Set.new
            to_process = types_depended_on

            until to_process.empty?
              type = to_process.first
              to_process.delete(type)

              next if result.include?(type)

              result << type

              to_process |= type.types_depended_on
            end

            result.select(&:registered?)
          end

          def inspect
            # :nocov:
            "#<Type:#{scoped_full_name}:0x#{object_id.to_s(16)} #{declaration_data}>"
            # :nocov:
          end
        end
      end
    end
  end
end
