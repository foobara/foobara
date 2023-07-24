module Foobara
  class Command
    module Concerns
      module InputSchema
        extend ActiveSupport::Concern

        class_methods do
          def input_schema(*args)
            if args.empty?
              @input_schema
            else
              raw_input_schema = args.first

              @input_schema = Foobara::Model::Schema::Attributes.new(raw_input_schema)

              errors = input_schema.schema_validation_errors

              if errors.present?
                raise "Schema is not valid!! #{errors.map(&:message).join(", ")}"
              end

              register_possible_errors
            end
          end

          def raw_input_schema
            input_schema.raw_schema
          end

          private

          def register_possible_errors
            register_cannot_cast_errors
            register_missing_required_attribute_errors
          end

          def register_cannot_cast_errors
            input_schema.schemas.each_pair do |input, schema|
              cast_to = schema.type

              possible_input_error(
                input,
                :cannot_cast,
                cast_to:,
                value: :duck
              )
            end
          end

          def register_missing_required_attribute_errors
            input_schema.required.each do |required_attribute|
              possible_input_error(
                required_attribute,
                :missing_required_attribute,
                attribute_name: :symbol
              )
            end
          end
        end

        delegate :input_schema, :raw_input_schema, to: :class
      end
    end
  end
end
