module Foobara
  class ErrorCollection
    class ErrorAlreadySetError < StandardError; end

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

    delegate :empty?, :partition, to: :error_array

    def errors
      error_array
    end

    def each_error(&)
      error_array.each(&)
    end

    def has_error?(error)
      raise ArgumentError unless error.is_a?(Error)

      error_array.include?(error)
    end

    def add_error(*args)
      error = if args.size == 1
                args.first
              else
                symbol, message, context = args
                Error.new(symbol:, message:, context:)
              end

      if has_error?(error)
        raise ErrorAlreadySetError, "cannot set #{error} more than once"
      end

      error_array << error
    end

    def add_errors(errors)
      Array.wrap(errors).each { |error| add_error(error) }
    end
  end
end
