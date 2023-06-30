require "foobara/models/type"

module Foobara
  module Models
    module Types
      class IntegerType < Type
        class << self
          def cast_from(object)
            case object
            when Integer
              object
            when /^\d+$/
              object.to_i
            else
              raise_type_conversion_error(object)
            end
          end
        end
      end
    end
  end
end
