module Foobara
  # TODO: move to foobara monorepo if this is generic...
  class CommandRegistry
    class Entry
      # TODO: add request transformers and response transformers
      attr_accessor :command_class,
                    :inputs_transformers,
                    :result_transformers,
                    :errors_transformers,
                    :serializers,
                    :allowed_rule,
                    :requires_authentication,
                    :authenticator

      def initialize(
        command_class,
        inputs_transformers:,
        result_transformers:,
        errors_transformers:,
        serializers:,
        allowed_rule:,
        requires_authentication:,
        authenticator:
      )
        self.command_class = command_class
        self.inputs_transformers = Util.array(inputs_transformers)
        self.result_transformers = Util.array(result_transformers)
        self.errors_transformers = Util.array(errors_transformers)
        self.serializers = Util.array(serializers)
        self.allowed_rule = allowed_rule
        self.requires_authentication = requires_authentication
        self.authenticator = authenticator
      end

      def manifest
        # TODO: need to delegate to the transformers when present, not the command!
        command_class.manifest(verbose: true)
      end

      def types_depended_on
        command_class.types_depended_on
      end
    end
  end
end
