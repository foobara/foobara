module Foobara
  module Common
    class ErrorCollection
      class ErrorAlreadySetError < StandardError; end

      class << self
        def symbolic(errors)
          new.tap do |collection|
            collection.add_errors(errors)
          end.symbolic
        end
      end

      attr_reader :error_array

      def initialize
        @error_array = []
      end

      def success?
        empty?
      end

      def has_errors?
        !empty?
      end

      delegate :empty?, :partition, :size, to: :error_array

      def errors
        error_array
      end

      def each_error(&)
        error_array.each(&)
      end

      def has_error?(error)
        unless error.is_a?(Error)
          # :nocov:
          raise ArgumentError, "Can only check if an Error class is in the collection"
          # :nocov:
        end

        error_array.include?(error)
      end

      def add_error(*args)
        error = if args.size == 3
                  symbol, message, context = args

                  { symbol:, message:, context: }
                elsif args.size == 1
                  arg = args.first

                  case arg
                  when Error
                    arg
                  when ErrorCollection
                    return add_errors(arg.errors)
                  when Hash
                    if arg.key?(:symbol) && arg.key?(:message)
                      arg
                    else
                      # :nocov:
                      raise ArgumentError,
                            "if passing a hash of error args it must include symbol and message at least"
                      # :nocov:
                    end
                  end
                end

        unless error
          # :nocov:
          raise ArgumentError, "Not sure how to convert #{args.inspect} into an error. Can handle a hash of error " \
                               "args or 3 arguments for symbol, message, and context, or, of course, an Error"
          # :nocov:
        end

        error = Error.new(**error) unless arg.is_a?(Error)

        if has_error?(error)
          raise ErrorAlreadySetError, "cannot set #{error} more than once"
        end

        error_array << error
      end

      def add_errors(errors)
        Array.wrap(errors).each { |error| add_error(error) }
      end

      def symbolic
        error_array.to_h do |error|
          [error.symbol, error.to_h]
        end
      end
    end
  end
end
