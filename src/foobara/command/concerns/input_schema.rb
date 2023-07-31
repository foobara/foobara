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

          def register_possible_errors(path = [], type = inputs_type)
            type.value_validators.each do |validator|
              symbol = validator.error_symbol
              context_schema = validator.error_context_schema

              # TODO: figure out how to eliminate this .compact, perhaps by putting path on the validator
              possible_input_error([*path, validator.attribute_name].compact, symbol, context_schema)
            end

            if type.children_types.present?
              type.children_types.each_pair do |attribute_name, attribute_type|
                child_path = [*path, attribute_name]

                possible_input_error(child_path, :cannot_cast, cast_to: :duck, value: :duck)
                register_possible_errors(child_path, attribute_type)
              end
            end
          end
        end

        delegate :input_schema, :raw_input_schema, to: :class
      end
    end
  end
end
