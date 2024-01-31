module Foobara
  # TODO: inherit array instead of delegating
  class ErrorCollection
    class ErrorAlreadySetError < StandardError; end

    class << self
      def to_h(errors)
        new.tap do |collection|
          collection.add_errors(errors)
        end.to_h
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

    foobara_delegate :empty?, :partition, :size, to: :error_array

    def errors
      error_array
    end

    def each_error(&)
      error_array.each(&)
    end

    def has_error?(error)
      unless error.is_a?(Error)
        # :nocov:
        raise ArgumentError, "Can only check if an Error instance is in the collection"
        # :nocov:
      end

      error_array.include?(error)
    end

    def add_error(error_or_collection_or_error_hash)
      error = case error_or_collection_or_error_hash
              when Error
                error_or_collection_or_error_hash
              when ErrorCollection
                return add_errors(error_or_collection_or_error_hash.errors)
              when Hash
                if error_or_collection_or_error_hash.key?(:symbol) &&
                   error_or_collection_or_error_hash.key?(:message)
                  Error.new(**error_or_collection_or_error_hash)
                else
                  # :nocov:
                  raise ArgumentError,
                        "if passing a hash of error args it must include symbol and message at least"
                  # :nocov:
                end
              else
                # :nocov:
                raise ArgumentError, "Not sure how to convert #{args.inspect} into an error. " \
                                     "Can handle a hash of error " \
                                     "args or 3 arguments for symbol, message, and context, or, of course, an Error"
                # :nocov:
              end

      if has_error?(error)
        raise ErrorAlreadySetError, "cannot set #{error} more than once"
      end

      error_array << error
    end

    def add_errors(errors)
      Util.array(errors).each { |error| add_error(error) }
    end

    def to_h
      error_array.to_h do |error|
        [error.key, error.to_h]
      end
    end

    def to_sentence
      Util.to_sentence(error_array.map(&:message))
    end

    def keys
      error_array.map(&:key)
    end
  end
end
