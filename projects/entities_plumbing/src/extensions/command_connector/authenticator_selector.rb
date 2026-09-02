module Foobara
  class CommandConnector
    class AuthenticatorSelector < Authenticator
      def relevant_entity_classes(request)
        outcome = selector.processor_for(request)

        if outcome.success?
          outcome.result&.relevant_entity_classes(request)
        end
      end
    end
  end
end
