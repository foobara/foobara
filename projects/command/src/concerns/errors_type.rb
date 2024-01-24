module Foobara
  class Command
    module Concerns
      module ErrorsType
        include Concern

        module ClassMethods
          def possible_errors
            error_context_type_map.values
          end

          def possible_error(*args)
            possible_error = case args.size
                             when 1
                               arg = args.first

                               if arg.is_a?(PossibleError)
                                 # TODO: test this code path
                                 # :nocov:
                                 arg
                                 # :nocov:
                               elsif arg.is_a?(::Class) && arg < Foobara::Error
                                 PossibleError.new(arg)
                               else
                                 # :nocov:
                                 raise ArgumentError, "Expected a PossibleError or an Error but got #{arg}"
                                 # :nocov:
                               end
                             when 2
                               symbol, error_class_or_context_type_declaration, data = args
                               error_class = to_runtime_error_class(symbol, error_class_or_context_type_declaration)
                               PossibleError.new(error_class, symbol:, data:)
                             else
                               # :nocov:
                               raise ArgumentError, "Expected an error or a symbol and error context type declaration"
                               # :nocov:
                             end

            register_possible_error_class(possible_error)
          end

          def possible_input_error(path, symbol, error_class_or_context_type_declaration, data = nil)
            error_class = to_input_error_class(symbol, error_class_or_context_type_declaration)

            # TODO: allow passing a path: to PossibleError.new, or maybe a prepend_path:
            possible_error = PossibleError.new(error_class, symbol:, data:)
            possible_error.prepend_path!(path)

            register_possible_error_class(possible_error)
          end

          # TODO: kill this method in favor of possible_errors
          def error_context_type_map
            @error_context_type_map ||= {}
          end

          def register_possible_error_class(possible_error)
            error_context_type_map[possible_error.key.to_s] = possible_error
          end

          # TODO: should we cache these???
          def to_input_error_class(symbol, context_type_declaration)
            Foobara::Value::DataError.subclass(
              symbol:,
              context_type_declaration:
            )
          end

          def to_runtime_error_class(symbol, context_type_declaration)
            Foobara::RuntimeError.subclass(
              symbol:,
              context_type_declaration:
            )
          end
        end
      end
    end
  end
end
