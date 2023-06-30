require "foobara/models/type"

module Foobara
  module Models
    module Types
      class AttributesType < Type
        class << self
          def cast_from(object)
            case object
            when Hash
              object.with_indifferent_access
            else
              raise_type_conversion_error(object)
            end
          end
        end
      end
    end
  end
end
