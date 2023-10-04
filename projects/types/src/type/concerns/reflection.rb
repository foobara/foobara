module Foobara
  module Types
    class Type < Value::Processor::Pipeline
      module Concerns
        module Reflection
          include Concern

          def types_depended_on
            result = Set.new
            result << self

            if element_type
              result |= element_type.types_depended_on
            end

            if element_types
              case element_types
              when Type
                result |= element_types.types_depended_on
              when ::Hash
                element_types.each_key do |key|
                  if key.is_a?(Type)
                    result |= key.types_depended_on
                  end
                end

                element_types.each_value do |value|
                  if value.is_a?(Type)
                    result |= value.types_depended_on
                  end
                end
              when ::Array
                element.each do |type|
                  result |= type.types_depended_on
                end
              end
            end

            result
          end
        end
      end
    end
  end
end
