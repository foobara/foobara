module Foobara
  class CommandConnector
    # TODO: should switch to a processor and give errors if the authenticator header is malformed
    class Authenticator < Value::Transformer
      attr_reader :block

      def initialize(symbol: nil, explanation: nil, &block)
        symbol ||= Util.non_full_name_underscore(self.class).to_sym
        explanation ||= symbol

        super(symbol:, explanation:)

        @block = block
      end

      def relevant_entity_classes
        nil
      end

      def symbol
        declaration_data[:symbol]
      end

      def explanation
        declaration_data[:explanation]
      end

      def transform(request)
        request.instance_exec(&to_proc)
      end

      def authenticate(request)
        process_value!(request)
      end

      def to_proc
        block
      end
    end
  end
end
