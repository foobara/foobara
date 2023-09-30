module Foobara
  # TODO: move to foobara monorepo if this is generic...
  class CommandRegistry
    class << self
      attr_accessor :default_inputs_transformer,
                    :default_result_transformer,
                    :default_errors_transformer,
                    :default_allowed_rule
    end

    foobara_delegate :default_inputs_transformer,
                     :default_result_transformer,
                     :default_errors_transformer,
                     :default_allowed_rule,
                     to: :class

    def register(
      command_class,
      inputs_transformer: default_inputs_transformer,
      result_transformer: default_result_transformer,
      errors_transformer: default_errors_transformer,
      allowed_rule: default_allowed_rule
    )
      entry = Entry.new(
        command_class,
        inputs_transformer:,
        result_transformer:,
        errors_transformer:,
        allowed_rule:
      )

      registry[command_class.full_entity_name] = entry
    end

    def registry
      @registry ||= {}
    end

    def allowed_rule_registry
      @allowed_rule_registry ||= {}
    end

    def allowed_rule(ruleish)
      allowed_rule = AllowedRule.to_allowed_rule(ruleish)

      unless allowed_rule.symbol
        raise "Cannot register a rule without a symbol"
      end

      @allowed_rule_registry[allowed_rule.symbol] = allowed_rule
    end

    def allowed_rules(hash)
      hash.map do |symbol, ruleish|
        allowed_rule = to_allowed_rule(ruleish)
        allowed_rule.symbol = symbol

        allowed_rule(allowed_rule)
      end
    end
  end
end
