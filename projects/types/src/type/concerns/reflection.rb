module Foobara
  module Types
    class Type < Value::Processor::Pipeline
      module Concerns
        module Reflection
          include Concern

          def types_depended_on(result = Set.new)
            return if result.include?(self)

            result << self

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

            result
          end

          def registered_types_depended_on
            types_depended_on.select(&:registered?)
          end
        end
      end
    end
  end
end
