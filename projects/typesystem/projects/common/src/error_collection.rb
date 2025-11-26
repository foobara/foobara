module Foobara
  class ErrorCollection < Array
    class ErrorAlreadySetError < StandardError; end

    class << self
      def to_h(errors)
        new.tap do |collection|
          collection.add_errors(errors)
        end.errors_hash
      end
    end

    def success?
      empty?
    end

    def has_errors?
      !empty?
    end

    def errors
      # :nocov:
      warn "DEPRECATED: Do not call ErrorCollection#errors instead just use the collection directly."
      self
      # :nocov:
    end

    def error_array
      # :nocov:
      warn "DEPRECATED: Do not call ErrorCollection#error_array instead just use the collection directly."
      self
      # :nocov:
    end

    def each_error(&)
      # :nocov:
      warn "DEPRECATED: This method will be deprecated in the coming version"
      each(&)
      # :nocov:
    end

    def has_error?(error)
      unless error.is_a?(Error)
        # :nocov:
        raise ArgumentError, "Can only check if an Error instance is in the collection"
        # :nocov:
      end

      include?(error)
    end

    def add_error(error_or_collection_or_error_hash)
      error = case error_or_collection_or_error_hash
              when Error
                error_or_collection_or_error_hash
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
                raise ArgumentError, "Not sure how to convert #{error_or_collection_or_error_hash.inspect} " \
                                     "into an error. Can handle a hash of error " \
                                     "args or 3 arguments for symbol, message, and context, or, of course, an Error"
                # :nocov:
              end

      if has_error?(error)
        raise ErrorAlreadySetError, "cannot set #{error} more than once"
      end

      self << error
    end

    def add_errors(errors)
      Util.array(errors).each { |error| add_error(error) }
    end

    def errors_hash
      each_with_object({}) do |error, hash|
        hash[error.key] = error.to_h
      end
    end

    def to_sentence
      Util.to_sentence(map(&:message))
    end

    def keys
      map(&:key)
    end

    def to_h
      # :nocov:
      warn "DEPRECATED: Use #errors_hash instead"
      errors_hash
      # :nocov:
    end
  end
end
