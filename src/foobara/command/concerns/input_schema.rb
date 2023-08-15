module Foobara
  class Command
    module Concerns
      module InputSchema
        extend ActiveSupport::Concern

        class_methods do
          def input_schema(*args)
            if args.empty?
              # TODO: rename to input_type or something like that
              return @input_schema if defined?(@input_schema)

              @input_schema = if superclass < Foobara::Command
                                input_schema(superclass.raw_input_schema)
                              end
            else
              # TODO: raise argument error if more than one argument given
              raw_input_schema = args.first

              @input_schema = type_declaration_handler_registry.type_for(raw_input_schema)

              register_possible_errors

              input_schema
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
