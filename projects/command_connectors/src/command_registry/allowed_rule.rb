module Foobara
  # TODO: move to foobara monorepo if this is generic...
  class CommandRegistry
    class AllowedRule
      class << self
        def to_allowed_rule(object)
          case object
          when AllowedRule
            object
          when ::String
            to_allowed_rule(object.to_sym)
          when ::Symbol
            allowed_rule = allowed_rule_registry[object]

            unless allowed_rule
              raise "No allowed rule found for #{object}"
            end

            allowed_rule
          when ::Hash
            rule_attributes = allowed_rule_attributes_type.process_value!(object)

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

            allowed_rule = new(&block)

            if rules.all?(&:explanation)
              allowed_rule.explanation = Util.to_or_sentence(rules.map(&:explanation))
            end

            allowed_rule
          else
            if object.respond_to?(:call)
              new(&object)
            else
              raise "Not sure how to convert #{object} into an AllowedRule object"
            end
          end
        end

        def allowed_rule_attributes_type
          @allowed_rule_attributes_type ||= TypeDeclarations::Namespace.global.type_for_declaration(
            symbol: :symbol,
            # TODO: add a function type and a way to union two types so that we can string or function type checking
            explanation: :duck,
            logic: :duck
          )
        end
      end

      attr_accessor :block, :explanation, :symbol

      def initialize(symbol: nil, explanation: nil, &block)
        self.symbol = symbol
        self.block = block
        self.explanation = explanation || symbol
      end

      def call
        block.call
      end

      def to_proc
        block
      end
    end
  end
end
