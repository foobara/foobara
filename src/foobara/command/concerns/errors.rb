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
          runtime_errors, input_errors = error_collection.partition { |e| e.is_a?(Foobara::Command::RuntimeError) }

          {
            runtime: runtime_errors.to_h { |error| [error.symbol, error.to_h] },
            input: input_errors.group_by(&:input).transform_values(&:to_h)
          }
        end

        private

        def add_error(error)
          error_collection.add_error(error)
          validate_error(error)
        end

        def add_input_error(*args, **opts)
          error = if args.size == 1 && opts.empty?
                    error = args.first

                    unless error.is_a?(Type::AttributeError)
                      raise ArgumentError, "expected an AttributeError or keyword arguments to construct one"
                    end

                    error
                  elsif args.empty? || (args.size == 1 && args.first.is_a?(Hash))
                    error_args = opts.merge(args.first || {})
                    symbol = error_args[:symbol]

                    raise "missing error symbol" unless symbol

                    # TODO: a way to eliminate this check?
                    klass = symbol == :unexpected_attributes ? UnexpectedAttributeError : AttributeError

                    klass.new(**error_args)
                  else
                    raise ArgumentError, "Invalid arguments given. Expected an error or keyword args for an error"
                  end

          add_error(error)
        end

        def add_runtime_error(*args, **opts)
          error = if args.size == 1 && opts.empty?
                    error = args.first

                    unless error.is_a?(Foobara::Command::RuntimeError)
                      # :nocov:
                      raise ArgumentError,
                            "expected a Foobara::Command::RuntimeError or keyword arguments to construct one"
                      # :nocov:
                    end

                    error
                  elsif args.empty? || (args.size == 1 && args.first.is_a?(Hash))
                    error_args = opts.merge(args.first || {})
                    symbol = error_args[:symbol]

                    raise "missing error symbol" unless symbol

                    Foobara::Command::RuntimeError.new(**error_args)
                  else
                    raise ArgumentError, "Invalid arguments given. Expected an error or keyword args for an error"
                  end

          add_error(error)
          halt!
        end

        def validate_error(error)
          # it has already been validated when it ran in the sub command
          return true if error.is_a?(Subcommands::FailedToExecuteSubcommand)

          symbol = error.symbol
          message = error.message
          context = error.context

          if !message.is_a?(String) || message.empty?
            raise "Bad error message, expected a string"
          end

          map = self.class.error_context_schema_map

          map = case error
                when Command::RuntimeError
                  map[:runtime]
                when Type::AttributeError
                  map[:input][error.path]
                else
                  # :nocov:
                  raise ArgumentError, "Unexpected error type for #{error}"
                  # :nocov:
                end

          possible_error_symbols = map.keys

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
