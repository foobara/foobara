module Foobara
  # TODO: move to foobara monorepo if this is generic...
  class CommandRegistry
    foobara_delegate :default_inputs_transformers,
                     :default_result_transformers,
                     :default_errors_transformers,
                     :default_allowed_rule,
                     to: :class

    attr_accessor :registry, :authenticator, :default_allowed_rule

    def initialize(authenticator: nil)
      self.authenticator = authenticator
      self.registry = {}
    end

    def register(
      command_class,
      inputs_transformers: nil,
      result_transformers: nil,
      errors_transformers: nil,
      allowed_rule: default_allowed_rule,
      requires_authentication: nil,
      authenticator: self.authenticator
    )
      entry = Entry.new(
        command_class,
        inputs_transformers: [*inputs_transformers, *default_inputs_transformers],
        result_transformers: [*result_transformers, *default_result_transformers],
        errors_transformers: [*errors_transformers, *default_errors_transformers],
        allowed_rule: allowed_rule && AllowedRule.to_allowed_rule(allowed_rule),
        requires_authentication:,
        authenticator:
      )

      registry[command_class.full_command_name] = entry
    end

    def [](name)
      key = if name.is_a?(Class)
              name.full_command_name
            else
              name.to_s
            end

      registry[key]
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

    def default_inputs_transformers
      @default_inputs_transformers ||= []
    end

    def add_default_inputs_transformer(transformer)
      default_inputs_transformers << transformer
    end

    def default_result_transformers
      @default_result_transformers ||= []
    end

    def add_default_result_transformer(transformer)
      default_result_transformers << transformer
    end

    def default_errors_transformers
      @default_errors_transformers ||= []
    end

    def add_default_errors_transformer(transformer)
      default_errors_transformers << transformer
    end
  end
end
