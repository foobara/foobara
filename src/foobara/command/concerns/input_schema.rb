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
              # TODO: make sure input schema is attributes
              @input_schema = Foobara::Models::Schema.new(raw_input_schema)

              errors = input_schema.schema_validation_errors

              if errors.present?
                raise "Schema is not valid!! #{errors.map(&:message).join(", ")}"
              end

              # This isn't a sustainable approach
              input_schema.strict_schema[:schemas].each_pair do |input, schema|
                schema[:type]

                possible_input_error(
                  input,
                  :cannot_cast,
                  cast_to: :symbol,
                  value: :duck
                )
              end
            end
          end

          def raw_input_schema
            input_schema.raw_schema
          end
        end

        attr_reader :inputs

        delegate :input_schema, :raw_input_schema, to: :class

        def method_missing(method_name, *args, &)
          if respond_to_missing_for_input_schema?(method_name)
            inputs[method_name]
          else
            super
          end
        end

        def respond_to_missing?(method_name, private = false)
          respond_to_missing_for_input_schema?(method_name, private) || super
        end

        def respond_to_missing_for_input_schema?(method_name, _private = false)
          inputs&.key?(method_name)
        end
      end
    end
  end
end
