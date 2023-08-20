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

              @input_schema = type_for_declaration(raw_input_schema)

              register_possible_errors

              input_schema
            end
          end

          def raw_input_schema
            input_schema.raw_declaration_data
          end

          private

          def register_possible_errors(path = [], type = inputs_type)
            type.possible_errors.each do |possible_error|
              p = possible_error[0]
              symbol = possible_error[1]
              error_class = possible_error[2]

              context_type_declaration = TypeDeclarations.error_context_type_declaration(error_class)

              possible_input_error([*path, *p], symbol, context_type_declaration)
            end
          end
        end

        delegate :input_schema, :raw_input_schema, to: :class
      end
    end
  end
end
