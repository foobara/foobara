module Foobara
  class Command < Service
    module Concerns
      module Errors
        include Concern

        module ClassMethods
          def lookup_input_error_class(symbol, path)
            key = ErrorKey.new(symbol:, path:, category: :data)
            key = key.to_s_type

            unless error_context_type_map.key?(key)
              # :nocov:
              raise "No error class was registered for #{key}"
              # :nocov:
            end

            error_context_type_map[key].error_class
          end

          def lookup_runtime_error_class(symbol)
            key = ErrorKey.new(symbol:, category: :runtime)
            key = key.to_s_type

            unless error_context_type_map.key?(key)
              # :nocov:
              raise "No error class was registered for #{key}"
              # :nocov:
            end

            error_context_type_map[key].error_class
          end

          def lookup_error_class(key)
            key = ErrorKey.to_s_type(key)

            unless error_context_type_map.key?(key)
              # :nocov:
              raise "No error class was registered for #{key}"
              # :nocov:
            end

            error_context_type_map[key].error_class
          end
        end

        attr_reader :error_collection

        def initialize
          @error_collection = ErrorCollection.new
          super
        end

        foobara_delegate :has_errors?, to: :error_collection

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
                    path = Util.array(error_args[:input] || error_args[:path])

                    error_args = error_args.except(:input)

                    unless symbol
                      # :nocov:
                      raise ArgumentError, "missing error symbol"
                      # :nocov:
                    end

                    unless path
                      # :nocov:
                      raise ArgumentError, "missing input"
                      # :nocov:
                    end

                    error_class = self.class.lookup_input_error_class(symbol, path)
                    error_class.new(**error_args, path:)
                  elsif [2, 3].include?(args.size)
                    input, symbol, message = args
                    context = opts

                    error_class = self.class.lookup_input_error_class(symbol, input)
                    error_class.new(path: Util.array(input), symbol:, context:, message:)
                  else
                    # :nocov:
                    raise ArgumentError,
                          "Invalid arguments given. Expected an error or args for an error"
                    # :nocov:
                  end

          add_error(error)
        end

        def add_subcommand_error(subcommand, error)
          error.runtime_path = [subcommand.class.full_command_symbol, *Util.array(error.runtime_path)]
          add_error(error)
          halt!
        end

        def add_runtime_error(*args, halt: true, **opts)
          error = if args.size == 1 && opts.empty? && (
            args.first.is_a?(::Class) || args.first.is_a?(Foobara::RuntimeError)
          )
                    error = args.first

                    if error.is_a?(::Class) && error < Foobara::RuntimeError
                      error = error.new
                    end

                    unless error.is_a?(Foobara::RuntimeError)
                      # :nocov:
                      raise ArgumentError,
                            "expected a Foobara::RuntimeError or keyword arguments to construct one"
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
                  elsif args.is_a?(::Array) && [1, 2].include?(args.size)
                    symbol, message = args
                    context = opts

                    error_class = self.class.lookup_runtime_error_class(symbol)
                    error_class.new(symbol:, context:, message:)
                  else
                    # :nocov:
                    raise ArgumentError, "Invalid arguments given. Expected an error or args/opts to build error"
                    # :nocov:
                  end

          add_error(error)
          if halt
            halt!
          else
            error
          end
        end

        def process_error(error)
          return error unless error.runtime_path.empty?

          context = error.context

          error_class = self.class.lookup_error_class(error.key)
          context_type = error_class.context_type

          error.context = context_type.process_value!(context || {})

          error
        end
      end
    end
  end
end
