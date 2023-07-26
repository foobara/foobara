module Foobara
  class Command
    module Concerns
      module ErrorSchema
        extend ActiveSupport::Concern

        class_methods do
          attr_accessor :error_context_schema_map

          def possible_input_error(path, symbol, context_schema = nil)
            path = Array.wrap(path)

            h = error_context_schema_map[:input]

            path.each do |path_part|
              h = h[path_part] ||= {}
            end

            h[symbol] = context_schema.presence
          end

          def error_context_schema_map
            @error_context_schema_map ||= {
              input: {},
              runtime: {}
            }
          end

          # TODO: delete this?
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
