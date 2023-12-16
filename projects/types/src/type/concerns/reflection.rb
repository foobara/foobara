module Foobara
  module Types
    class Type < Value::Processor::Pipeline
      module Concerns
        module Reflection
          include Concern

          # as soon as we hit a registered type, don't go further down that path
          def types_depended_on(result = nil)
            start = result.nil?

            if start
              result = Set.new
            elsif result.include?(self)
              return
            else
              result << self
            end

            base_type&.types_depended_on(result)
            element_type&.types_depended_on(result)

            if element_types
              case element_types
              when Type
                element_types.types_depended_on(result)
              when ::Hash
                element_types.each_value do |value|
                  if value.is_a?(Type)
                    value.types_depended_on(result)
                  end
                end
              when ::Array
                element_types.each do |type|
                  type.types_depended_on(result)
                end
              end
            end

            possible_errors.values.uniq.each do |error_class|
              error_class.types_depended_on(result)
            end

            start ? result.select(&:registered?) : result
          end
        end
      end
    end
  end
end
