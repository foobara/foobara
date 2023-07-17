module Foobara
  class ErrorCollection
    class ErrorAlreadySetError < StandardError; end

    attr_reader :error_hash

    def initialize
      @error_hash = {}.with_indifferent_access
    end

    def success?
      !has_errors?
    end

    def has_errors?
      error_hash.present?
    end

    def empty?
      error_hash.blank?
    end

    def errors
      error_hash.values
    end

    def each_error(&)
      error_hash.each_value(&)
    end

    def has_error?(error)
      symbol = case error
               when Error
                 error.symbol
               when Symbol
                 error
               when String
                 error.to_sym
               end

      error_hash.key?(symbol)
    end

    def add_error(*args)
      error = if args.size == 1
                args.first
              else
                symbol, message, context = args
                Error.new(symbol:, message:, context:)
              end

      symbol = error.symbol

      if has_error?(symbol)
        raise ErrorAlreadySetError, "cannot set #{symbol} more than once"
      end

      error_hash[symbol] = error
    end
  end
end
