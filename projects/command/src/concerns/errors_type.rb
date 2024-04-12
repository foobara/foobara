module Foobara
  class Command
    module Concerns
      module ErrorsType
        include Concern

        module ClassMethods
          def process_error_constants
            return if @error_constants_processed

            @error_constants_processed = true

            Util.constant_values(self, extends: Foobara::RuntimeError).each do |error_class|
              key = PossibleError.new(error_class).key.to_s

              unless error_context_type_map.key?(key)
                possible_error error_class
              end
            end
          end

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

          def possible_input_error(
            path,
            symbol_or_error_class,
            error_class_or_context_type_declaration = {},
            data = nil
          )
            error_class, symbol = if symbol_or_error_class.is_a?(Class)
                                    [symbol_or_error_class, symbol_or_error_class.symbol]
                                  else
                                    [
                                      to_input_error_class(
                                        symbol_or_error_class,
                                        error_class_or_context_type_declaration
                                      ),
                                      symbol_or_error_class
                                    ]
                                  end

            possible_error = PossibleError.new(error_class, symbol:, data:)
            possible_error.prepend_path!(path)

            possible_error.manually_added = true
            register_possible_error_class(possible_error)
          end

          def manually_added_possible_input_errors
            @manually_added_possible_input_errors ||= []
          end

          # TODO: kill this method in favor of possible_errors
          def error_context_type_map
            process_error_constants
            @error_context_type_map ||= if superclass < Foobara::Command
                                          superclass.error_context_type_map.dup
                                        end || {}
          end

          def register_possible_error_class(possible_error)
            if possible_error.manually_added
              manually_added_possible_input_errors << possible_error
            end

            error_context_type_map[possible_error.key.to_s] = possible_error
          end

          def unregister_possible_error_if_registered(possible_error)
            key = possible_error.key.to_s
            error_context_type_map.delete(key)
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
