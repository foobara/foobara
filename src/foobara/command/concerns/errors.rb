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
          error = process_error(error)
          error_collection.add_error(error)
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
                    klass = symbol == :unexpected_attribute ? UnexpectedAttributeError : AttributeError

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

        def process_error(error)
          # it has already been processed when it ran in the sub command
          return error if error.is_a?(Subcommands::FailedToExecuteSubcommand)

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

          unless possible_error_symbols.include?(symbol)
            raise "Invalid error symbol #{symbol} expected one of #{possible_error_symbols}"
          end

          # TODO: need to pass in schema registries here
          context_schema = Foobara::Model::Schema::Attributes.new(map[symbol])

          if context_schema.present?
            error.context = context_schema.to_type.process!(context || {})
          elsif context.present?
            raise "There's no context schema declared for #{symbol}"
          end

          error
        end
      end
    end
  end
end
