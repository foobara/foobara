module Foobara
  class Model
    class TypeBuilder
      class Attributes < TypeBuilder
        def to_type
          Type.new(**to_args)
        end

        def to_args
          {
            casters:,
            value_processors:
          }
        end

        def value_processors
          [
            *default_transformers,
            *required_field_validators
          ]
        end

        def default_transformers
          schema.defaults.map do |(attribute_name, default_value)|
            Transformers::Attribute::AddDefault.new(attribute_name:, default_value:)
          end
        end

        def required_field_validators
          schema.required.map do |attribute_name|
            Validators::Attribute::ValidateRequiredAttributesPresent.new(attribute_name:)
          end
        end

        def base_type
          @base_type ||= Type[:attributes]
        end

        def casters
          base_type.casters
        end
      end
    end
  end
end
