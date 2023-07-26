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
          runtime_errors, input_errors = error_collection.partition { |e| e.is_a?(RuntimeError) }

          {
            runtime: runtime_errors.to_h { |error| [error.symbol, error.to_h] },
            input: structured_input_errors
          }
        end

        private

        def structured_input_errors
          hash = {}

          input_errors.each do |error|
            h = hash
            error.path.each do |path_part|
              h = h[path_part] ||= {}
            end

            h[error.symbol] = error
          end

          hash
        end

        def add_error(error)
          error_collection.add_error(error)
          validate_error(error)
        end

        def add_input_error(symbol:, attribute_name:, path: [attribute_name], **args)
          # TODO: a way to eliminate this check?
          klass = symbol == :unexpected_attributes ? UnexpectedAttributeError : AttributeError

          error = klass.new(symbol:, path:, attribute_name:, **args)
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
                when UnexpectedAttributeError
                  map[:input][:_unexpected_attribute]
                when AttributeError
                  attribute_name = error.attribute_name

                  map[:input][attribute_name]
                end

          binding.pry unless map
          raise "Unexpected error type for #{error}" unless map

          possible_error_symbols = map.keys
          # TODO: probably should store the schema objects and not the hashes?
          context_schema = Foobara::Model::Schema::Attributes.new(map[symbol])

          unless possible_error_symbols.include?(symbol)
            raise "Invalid error symbol #{symbol} expected one of #{possible_error_symbols}"
          end

          if context_schema.present?
            errors = Model::TypeBuilder.type_for(context_schema).validation_errors(context.presence || {})
            raise "Invalid context schema #{context}: #{errors}" if errors.present?
          elsif context.present?
            raise "There's no context schema declared for #{symbol}"
          end
        end
      end
    end
  end
end
