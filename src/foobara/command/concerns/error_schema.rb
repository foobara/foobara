module Foobara
  class Command
    module Concerns
      module ErrorSchema
        extend ActiveSupport::Concern

        class_methods do
          attr_accessor :error_context_schema_map

          def possible_input_error(path, symbol, context_schema = nil)
            error_context_schema_map[:input][path][symbol] = context_schema.presence
          end

          def error_context_schema_map(map = nil, path = nil, schema_to_process = nil)
            if map.nil?
              return @error_context_schema_map if @error_context_schema_map

              inputs_map = {}

              error_context_schema_map(inputs_map, [], input_schema)

              @error_context_schema_map = {
                input: inputs_map,
                runtime: {}
              }
            else
              map[path] = {}

              if schema_to_process.is_a?(Foobara::Model::Schema::Attributes)
                schema_to_process.schemas.each_pair do |attribute_name, schema|
                  attribute_path = [*path, attribute_name]

                  error_context_schema_map(map, attribute_path, schema)
                end
              end
            end
          end

          def possible_input_errors(inputs_to_possible_errors)
            inputs_to_possible_errors.each_pair do |input, possible_errors|
              Array.wrap(possible_errors).each do |possible_error|
                case possible_error
                when Symbol
                  possible_input_error(input, arg)
                when Hash
                  arg.each_pair do |symbols, context_schema|
                    Array.wrap(symbols).each do |symbol|
                      possible_input_error(input, symbol, context_schema)
                    end
                  end
                else
                  raise ArgumentError, "expected symbols and hashes"
                end
              end
            end
          end

          def possible_error(symbol, context_schema = nil)
            error_context_schema_map[:runtime][symbol] = context_schema.presence
          end

          def possible_errors(*args)
            raise ArgumentError, "at least one argument" if args.empty?

            args.each do |arg|
              case arg
              when Symbol
                possible_error(arg)
              when Hash
                arg.each_pair do |symbols, context_schema|
                  Array.wrap(symbols).each do |symbol|
                    possible_error(symbol, context_schema)
                  end
                end
              else
                raise ArgumentError, "expected symbols and hashes"
              end
            end
          end
        end
      end
    end
  end
end
