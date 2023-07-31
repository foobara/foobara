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
            value_processors:,
            children_types:
          }
        end

        def children_types
          @children_types ||= schemas.transform_values do |schema|
            TypeBuilder.type_for(schema)
          end
        end

        def value_processors
          [
            unexpected_attributes_validator,
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
            # we need to get paths into here... not attribute_name specifically
            Validators::Attribute::MissingRequiredAttribute.new(attribute_name)
          end
        end

        def unexpected_attributes_validator
          Validators::Attribute::UnexpectedAttribute.new(schema.valid_attribute_names)
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
