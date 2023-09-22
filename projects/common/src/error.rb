module Foobara
  class Error < StandardError
    # TODO: rename :path to data_path
    attr_accessor :error_key, :message, :context, :is_fatal

    class << self
      def symbol
        Util.non_full_name(self).underscore.gsub(/_error$/, "").to_sym
      end

      def path
        ErrorKey::EMPTY_PATH
      end

      def runtime_path
        ErrorKey::EMPTY_PATH
      end

      def category
        nil
      end

      def message
        nil
      end

      def context
        nil
      end

      def fatal?
        false
      end

      def to_h
        {
          category:,
          symbol:,
          # TODO: this is a bad dependency direction but maybe time to bite the bullet and finally merge these...
          context_type_declaration: context_type.declaration_data,
          is_fatal: fatal?
        }
      end
    end

    delegate :runtime_path,
             :runtime_path=,
             :category,
             :category=,
             :path,
             :path=,
             :symbol,
             :symbol=,
             to: :error_key

    # TODO: seems like we should not allow the symbol to vary within instances of a class
    # TODO: any items serializable in self.class.to_h should not be overrideable like this...
    def initialize(
      path: self.class.path,
      runtime_path: self.class.runtime_path,
      category: self.class.category,
      message: self.class.message,
      symbol: self.class.symbol,
      context: self.class.context,
      is_fatal: self.class.fatal?
    )
      self.error_key = ErrorKey.new

      self.symbol = symbol
      self.message = message
      self.context = context
      self.category = category
      self.path = path
      self.runtime_path = runtime_path
      self.is_fatal = is_fatal

      if !self.message.is_a?(String) || message.empty?
        # :nocov:
        raise "Bad error message, expected a string"
        # :nocov:
      end

      super(message)
    end

    def fatal?
      is_fatal
    end

    def key
      error_key.to_s
    end

    def ==(other)
      equal?(other) || eql?(other)
    end

    def eql?(other)
      return false unless other.is_a?(Error)

      symbol == other.symbol
    end

    def prepend_path!(...)
      error_key.prepend_path!(...)
      self
    end

    def to_h
      {
        key:,
        path:,
        runtime_path:,
        category:,
        symbol:,
        message:,
        context:,
        is_fatal: fatal?
      }
    end
  end
end
