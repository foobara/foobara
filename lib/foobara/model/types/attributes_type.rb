module Foobara
  class Model
    module Types
      class AttributesType < Type
        class << self
          def cast_from(object)
            case object
            when Hash
              object.with_indifferent_access
            else
              raise "There must but a bug in can_cast? for #{symbol} #{object.inspect}"
            end
          end

          def can_cast?(object)
            object.is_a?(Hash)
          end
        end
      end
    end
  end
end
