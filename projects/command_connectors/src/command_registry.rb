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
        allowed_rule: allowed_rule && to_allowed_rule(allowed_rule),
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
      allowed_rule = to_allowed_rule(ruleish)

      unless allowed_rule.symbol
        # :nocov:
        raise "Cannot register a rule without a symbol"
        # :nocov:
      end

      allowed_rule_registry[allowed_rule.symbol] = allowed_rule
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

    def to_allowed_rule(object)
      case object
      when AllowedRule, nil
        object
      when ::String
        to_allowed_rule(object.to_sym)
      when ::Symbol
        allowed_rule = allowed_rule_registry[object]

        unless allowed_rule
          # :nocov:
          raise "No allowed rule found for #{object}"
          # :nocov:
        end

        allowed_rule
      when ::Hash
        rule_attributes = AllowedRule.allowed_rule_attributes_type.process_value!(object)

        allowed_rule = to_allowed_rule(rule_attributes[:logic])

        if rule_attributes.key?(:symbol)
          allowed_rule.symbol = rule_attributes[:symbol]
        end

        if rule_attributes.key?(:explanation)
          allowed_rule.explanation = rule_attributes[:explanation]
        end

        allowed_rule.explanation ||= allowed_rule.symbol

        allowed_rule
      when ::Array
        rules = object.map { |ruleish| to_allowed_rule(ruleish) }

        procs = rules.map(&:block)

        block = proc do
          procs.any?(&:call)
        end

        allowed_rule = AllowedRule.new(&block)

        if rules.all?(&:explanation)
          allowed_rule.explanation = Util.to_or_sentence(rules.map(&:explanation))
        end

        allowed_rule
      else
        if object.respond_to?(:call)
          AllowedRule.new(&object)
        else
          # :nocov:
          raise "Not sure how to convert #{object} into an AllowedRule object"
          # :nocov:
        end
      end
    end
  end
end
