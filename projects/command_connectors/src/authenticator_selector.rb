require_relative "authenticator"

module Foobara
  class CommandConnector
    # TODO: should switch to a processor and give errors if the authenticator header is malformed
    class AuthenticatorSelector < Authenticator
      attr_accessor :authenticators

      def initialize(authenticators:, symbol: nil, explanation: nil, &block)
        self.authenticators = authenticators

        symbol ||= authenticators.map(&:symbol).map(&:to_s).join("_or_").to_sym
        explanation ||= authenticators.map(&:explanation).join(", or ")

        super(symbol:, explanation:)

        @block = block
      end

      def selector
        @selector ||= Value::Processor::Selection.new(processors: authenticators, error_if_none_applicable: false)
      end

      def authenticate(request)
        selector.process_value!(request)
      end
    end
  end
end
