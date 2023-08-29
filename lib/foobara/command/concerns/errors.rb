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
          runtime_errors, input_errors = error_collection.partition do |e|
            e.is_a?(Foobara::Command::RuntimeCommandError)
          end

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

                    unless error.is_a?(Value::DataError)
                      # :nocov:
                      raise ArgumentError, "expected an DataError or keyword arguments to construct one"
                      # :nocov:
                    end

                    error
                  elsif args.empty? || (args.size == 1 && args.first.is_a?(Hash))
                    error_args = opts.merge(args.first || {})
                    symbol = error_args[:symbol]
                    input = error_args[:input]

                    error_args = error_args.except(:input)

                    unless symbol
                      # :nocov:
                      raise ArgumentError, "missing error symbol"
                      # :nocov:
                    end
                    unless input
                      # :nocov:
                      raise ArgumentError, "missing input"
                      # :nocov:
                    end

                    Value::DataError.new(**error_args.merge(path: [input]))
                  else
                    # :nocov:
                    raise ArgumentError, "Invalid arguments given. Expected an error or keyword args for an error"
                    # :nocov:
                  end

          add_error(error)
        end

        def add_runtime_error(*args, **opts)
          error = if args.size == 1 && opts.empty?
                    error = args.first

                    unless error.is_a?(Foobara::Command::RuntimeCommandError)
                      # :nocov:
                      raise ArgumentError,
                            "expected a Foobara::Command::RuntimeCommandError or keyword arguments to construct one"
                      # :nocov:
                    end

                    error
                  elsif args.empty? || (args.size == 1 && args.first.is_a?(Hash))
                    error_args = opts.merge(args.first || {})
                    symbol = error_args[:symbol]

                    unless symbol
                      # :nocov:
                      raise ArgumentError, "missing error symbol"
                      # :nocov:
                    end

                    Foobara::Command::RuntimeCommandError.new(**error_args)
                  else
                    # :nocov:
                    raise ArgumentError, "Invalid arguments given. Expected an error or keyword args for an error"
                    # :nocov:
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
            # :nocov:
            raise "Bad error message, expected a string"
            # :nocov:
          end

          map = self.class.error_context_type_map

          map = case error
                when Command::RuntimeCommandError
                  map[:runtime]
                when Value::DataError
                  map[:input][error.path]
                else
                  # :nocov:
                  raise ArgumentError, "Unexpected error type for #{error}"
                  # :nocov:
                end

          possible_error_symbols = map.keys

          unless possible_error_symbols.include?(symbol)
            # :nocov:
            raise "Invalid error symbol #{symbol} expected one of #{possible_error_symbols}"
            # :nocov:
          end

          type_declaration = map[symbol]
          context_type = type_for_declaration(type_declaration)

          error.context = context_type.process!(context || {})

          error
        end
      end
    end
  end
end
