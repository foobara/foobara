module Foobara
  class Command
    module Concerns
      module Errors
        extend ActiveSupport::Concern

        attr_reader :error_collection

        def initialize
          @error_collection = ErrorCollection.new
        end

        delegate :has_errors?, to: :error_collection

        def error_hash
          error_collection.to_h
        end

        private

        def add_error(error)
          error_collection.add_error(error)
          validate_error(error)
        end

        def add_input_error(**args)
          error = InputError.new(**args)
          add_error(error)
        end

        def add_runtime_error(**args)
          error = RuntimeError.new(**args)
          add_error(error)
          halt!
        end

        def validate_error(error)
          symbol = error.symbol
          message = error.message
          context = error.context

          if !message.is_a?(String) || message.empty?
            raise "Bad error message, expected a string"
          end

          map = self.class.error_context_schema_map

          map = case error
                when RuntimeError
                  map[:runtime]
                when InputError
                  input = error.input

                  map[:input][input]
                else
                  raise "Unexpected error type for #{error}"
                end

          possible_error_symbols = map.keys
          # TODO: probably should store the schema objects and not the hashes?
          context_schema = Foobara::Models::Schema.new(map[symbol])

          unless possible_error_symbols.include?(symbol)
            raise "Invalid error symbol #{symbol} expected one of #{possible_error_symbols}"
          end

          if context_schema.present?
            errors = context_schema.validation_errors(context.presence || {})
            raise "Invalid context schema #{context}: #{errors}" if errors.present?
          elsif context.present?
            raise "There's no context schema declared for #{symbol}"
          end
        end
      end
    end
  end
end
