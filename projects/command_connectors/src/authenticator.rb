module Foobara
  class CommandConnector
    class Authenticator < TypeDeclarations::TypedTransformer
      class << self
        attr_writer :default_symbol
        attr_accessor :default_explanation, :default_block

        def subclass(to: nil, symbol: nil, explanation: nil, &default_block)
          klass = super(to:, from: Request, &nil)

          klass.default_symbol = symbol if symbol
          klass.default_explanation = explanation if explanation
          klass.default_block = default_block if default_block

          klass
        end

        def default_symbol
          @default_symbol || Util.non_full_name_underscore(self)&.to_sym
        end

        def instance
          @instance ||= new
        end
      end

      attr_accessor :symbol
      attr_reader :block, :explanation

      def initialize(symbol: nil, explanation: nil, &block)
        self.symbol = symbol || self.class.default_symbol
        @explanation = explanation || self.class.default_explanation || self.symbol

        super()

        @block = block || self.class.default_block
      end

      def transform(request)
        request.instance_exec(&to_proc)
      end

      def authenticate(request)
        if applicable?(request)
          process_value!(request)
        end
      end

      def to_proc
        block
      end
    end
  end
end
