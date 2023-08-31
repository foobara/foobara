module Foobara
  class Command
    module Concerns
      module ErrorsType
        extend ActiveSupport::Concern

        class_methods do
          def errors_type_declaration
            declaration = {}

            error_context_type_map.each_pair do |key, error_class|
              declaration[key] = ErrorKey.to_h(key).merge(
                key:,
                symbol: error_class.symbol,
                context_type_declaration: error_class.context_type.declaration_data
              )
            end

            declaration
          end

          def possible_error(*args)
            case args.size
            when 1
              error_class = args.first
              symbol = error_class.symbol
            when 2
              symbol, error_class_or_context_type_declaration = args
              error_class = to_runtime_error_class(symbol, error_class_or_context_type_declaration)
            else
              # :nocov:
              raise ArgumentError, "Expected an error or a symbol and error context type declaration"
              # :nocov:
            end

            error_key = ErrorKey.new(symbol:, category: :runtime)

            register_possible_error_class(error_key, error_class)
          end

          def possible_input_error(path, symbol, error_class_or_context_type_declaration)
            error_class = to_input_error_class(symbol, error_class_or_context_type_declaration)

            key = ErrorKey.new(symbol:, path:, category: error_class.category)

            register_possible_error_class(key, error_class)
          end

          # TODO: rename... this maps keys to error_classes...
          def error_context_type_map
            @error_context_type_map ||= {}
          end

          def register_possible_error_class(key, error_class)
            key = key.to_s

            if error_context_type_map.key?(key)
              # :nocov:
              raise "Cannot set #{key} twice"
              # :nocov:
            end

            error_context_type_map[key] = error_class
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
