module Foobara
  module Common
    class Error < StandardError
      attr_writer :symbol, :message, :context

      class << self
        def symbol
          name.demodulize.underscore.gsub(/_error$/, "").to_sym
        end

        # TODO: move this to TypeDeclarations extension!!
        def subclass(superclass = self, symbol:, context_type_declaration:, message: nil)
          Class.new(superclass) do
            singleton_class.define_method :symbol do
              symbol
            end

            singleton_class.define_method :context_type_declaration do
              context_type_declaration
            end

            if message.present?
              singleton_class.define_method :message do
                message
              end
            end
          end
        end
      end

      def initialize(message: nil, symbol: self.class.symbol, context: {})
        self.symbol = symbol
        self.message = message
        self.context = context

        super(message)
      end

      def symbol
        @symbol || self.class.symbol || super
      end

      def message
        @message || self.class.message || super
      end

      def context
        @context || self.class.context || super
      end

      def ==(other)
        equal?(other) || eql?(other)
      end

      def eql?(other)
        return false unless other.is_a?(Error)

        symbol == other.symbol
      end

      def to_h
        {
          symbol:,
          message:,
          context:
        }
      end
    end
  end
end
