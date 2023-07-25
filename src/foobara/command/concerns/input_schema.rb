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

              errors = if input_schema.has_errors?
                         input_schema.errors
                       else
                         input_schema.schema_validation_errors
                       end

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
            # These should be derived somehow from the validators
            register_cannot_cast_errors
            register_missing_required_attribute_errors
            register_unexpected_attribute_errors
          end

          def register_cannot_cast_errors
            input_schema.schemas.each_key do |input|
              possible_input_error(
                input,
                :cannot_cast,
                cast_to: :duck,
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

          def register_unexpected_attribute_errors
            possible_input_error(
              :_unexpected_attribute,
              :unexpected_attributes,
              attribute_name: :symbol,
              value: :duck
            )
          end
        end

        delegate :input_schema, :raw_input_schema, to: :class
      end
    end
  end
end
