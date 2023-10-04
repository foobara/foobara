module Foobara
  # TODO: move to foobara monorepo if this is generic...
  class CommandRegistry
    class Entry
      # TODO: add request transformers and response transformers
      attr_accessor :command_class,
                    :inputs_transformers,
                    :result_transformers,
                    :errors_transformers,
                    :allowed_rule,
                    :requires_authentication,
                    :authenticator

      def initialize(
        command_class,
        inputs_transformers:,
        result_transformers:,
        errors_transformers:,
        allowed_rule:,
        requires_authentication:,
        authenticator:
      )
        self.command_class = command_class
        self.inputs_transformers = Util.array(inputs_transformers)
        self.result_transformers = Util.array(result_transformers)
        self.errors_transformers = Util.array(errors_transformers)
        self.allowed_rule = allowed_rule
        self.requires_authentication = requires_authentication
        self.authenticator = authenticator
      end
    end
  end
end
