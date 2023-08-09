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

              # TODO: need to pass in schema registries here
              @input_schema = Foobara::Model::Schemas::Attributes.new(raw_input_schema)

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
            type.possible_errors.each do |possible_error|
              p = possible_error[0]
              symbol = possible_error[1]
              context_schema = possible_error[2]

              possible_input_error([*path, *p], symbol, context_schema)
            end
          end
        end

        delegate :input_schema, :raw_input_schema, to: :class
      end
    end
  end
end
