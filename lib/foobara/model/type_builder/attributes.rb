module Foobara
  class Model
    class TypeBuilder
      class Attributes < TypeBuilder
        delegate :schemas, to: :schema

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
            *required_field_validators,
            unexpected_attributes_validator,
            *cast_value_processors,
            Processors::HaltUnlessSuccess.new,
            *processors_for_each_attribute
          ]
        end

        def default_transformers
          schema.defaults.map do |(attribute_name, default_value)|
            Transformers::Attribute::AddDefault.new(attribute_name:, default_value:)
          end
        end

        def required_field_validators
          schema.required.map do |attribute_name|
            Validators::Attribute::ValidateRequiredAttributesPresent.new(attribute_name:, path: [*path, attribute_name])
          end
        end

        def unexpected_attributes_validator
          Validators::Attribute::ValidateAllAttributesExpected.new(
            allowed_attribute_names: schema.valid_attribute_names,
            path:
          )
        end

        # TODO: rename/delete
        def cast_value_processors
          schemas.map do |(attribute_name, schema)|
            attribute_type = TypeBuilder.type_for(schema)
            Processors::Attribute::CastValue.new(attribute_name:, attribute_type:, path: [*path, attribute_name])
          end
        end

        def processors_for_each_attribute
          schemas.map do |(attribute_name, schema)|
            attribute_type = TypeBuilder.type_for(schema)
            attribute_type.value_processors
            # Processors::Attribute::CastValue.new(attribute_name:, attribute_type:, path: [*path, attribute_name])
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
