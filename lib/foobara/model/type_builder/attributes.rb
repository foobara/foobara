module Foobara
  class Model
    class TypeBuilder
      class Attributes < TypeBuilder
        delegate :schemas, to: :schema

        def to_args
          super.merge(children_types:)
        end

        def children_types
          @children_types ||= schemas.transform_values do |schema|
            TypeBuilder.type_for(schema)
          end
        end

        def value_validators
          [*super, unexpected_attributes_validator]
        end

        def unexpected_attributes_validator
          Validators::Attribute::UnexpectedAttribute.new(schema.valid_attribute_names)
        end

        # TODO: can we eliminate this concept?
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
