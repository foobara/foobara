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
          end

          def raw_input_schema
            input_schema.raw_schema
          end
        end

        delegate :input_schema, :raw_input_schema, to: :class
      end
    end
  end
end
