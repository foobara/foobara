module Foobara
  class Command
    module Concerns
      module Errors
        extend ActiveSupport::Concern

        class_methods do
          # TODO: what to do if we have two subcommands in different domains with the same name??
          # Seems like we need to fully qualify these with their domain, right?
          def runtime_path_symbol
            symbol = name.demodulize.underscore

            [
              domain&.runtime_path_symbol,
              symbol
            ].compact.join(".").to_sym
          end

          def lookup_input_error_class(symbol, path)
            key = ErrorKey.new(symbol:, path:, category: :data)
            key = key.to_s

            unless error_context_type_map.key?(key)
              # :nocov:
              raise "No error class was registered for #{key}"
              # :nocov:
            end

            error_context_type_map[key]
          end

          def lookup_runtime_error_class(symbol)
            key = ErrorKey.new(symbol:, category: :runtime)
            key = key.to_s

            unless error_context_type_map.key?(key)
              # :nocov:
              raise "No error class was registered for #{key}"
              # :nocov:
            end

            error_context_type_map[key]
          end

          def lookup_error_class(key)
            key = key.to_s

            unless error_context_type_map.key?(key)
              # :nocov:
              raise "No error class was registered for #{key}"
              # :nocov:
            end

            error_context_type_map[key]
          end
        end

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
                    path = Array.wrap(error_args[:input] || error_args[:path])

                    error_args = error_args.except(:input)

                    unless symbol.present?
                      # :nocov:
                      raise ArgumentError, "missing error symbol"
                      # :nocov:
                    end
                    unless path.present?
                      # :nocov:
                      raise ArgumentError, "missing input"
                      # :nocov:
                    end

                    error_class = self.class.lookup_input_error_class(symbol, path)
                    error_class.new(**error_args.merge(path:))
                  else
                    # :nocov:
                    raise ArgumentError, "Invalid arguments given. Expected an error or keyword args for an error"
                    # :nocov:
                  end

          add_error(error)
        end

        def add_subcommand_error(subcommand, error)
          error.runtime_path = [subcommand.class.runtime_path_symbol, *Array.wrap(error.runtime_path)]
          add_error(error)
          halt!
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

                    error_class = self.class.lookup_runtime_error_class(symbol)
                    error_class.new(**error_args)
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
          return error if error.runtime_path.present?

          context = error.context

          error_class = self.class.lookup_error_class(error.key)
          context_type = error_class.context_type

          error.context = context_type.process!(context || {})

          error
        end
      end
    end
  end
end
