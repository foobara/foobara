module Foobara
  # TODO: move to foobara monorepo if this is generic...
  class CommandRegistry
    class Entry
      attr_accessor :command_class,
                    :inputs_transformer,
                    :result_transformer,
                    :errors_transformer,
                    :allowed_rule

      def register(command_class, inputs_transformer:, result_transformer:, errors_transformer:, allowed_rule:)
        self.command_class = command_class
        self.inputs_transformer = inputs_transformer
        self.result_transformer = result_transformer
        self.errors_transformer = errors_transformer
        self.allowed_rule = allowed_rule
      end
    end
  end
end
