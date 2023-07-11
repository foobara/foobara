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

          def schema_validation_errors_for(strict_schema)
            schemas = strict_schema[:schemas]

            if schemas.blank?
              "attributes type must have a schemas entry"
            elsif schemas.keys.any? { |key| !key.is_a?(Symbol) }
              "Attributes must have all symbolic keys"
            end
          end
        end
      end
    end
  end
end
