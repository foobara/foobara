module Foobara
  # TODO: move to foobara monorepo if this is generic...
  class CommandRegistry
    attr_accessor :registry, :authenticator, :default_allowed_rule, :short_name_to_transformed_command

    def initialize(authenticator: nil)
      self.authenticator = authenticator
      self.registry = {}
      self.short_name_to_transformed_command = {}
    end

    def register(registerable, *, **)
      case registerable
      when Class
        unless registerable < Command
          # :nocov:
          raise "Don't know how to register #{registerable} (#{registerable.class})"
          # :nocov:
        end

        transformed_command_class = transform_command_class(registerable, *, **)

        registry[transformed_command_class.full_command_name] = transformed_command_class

        short_name = transformed_command_class.command_name
        existing_entry = short_name_to_transformed_command[short_name]

        short_name_to_transformed_command[short_name] = if existing_entry
                                                          [*existing_entry, transformed_command_class]
                                                        else
                                                          transformed_command_class
                                                        end

        transformed_command_class
      when Module
        if registerable.foobara_organization?
          registerable.foobara_domains.map { |domain| register(domain, *, **) }
        elsif registerable.foobara_domain?
          registerable.foobara_each_command(lookup_in_children: false) do |command_class|
            register(command_class, *, **)
          end
        else
          # :nocov:
          raise "Don't know how to register #{registerable} (#{registerable.class})"
          # :nocov:
        end
      else
        # :nocov:
        raise "Don't know how to register #{registerable} (#{registerable.class})"
        # :nocov:
      end
    end

    def transform_command_class(
      command_class,
      capture_unknown_error: nil,
      inputs_transformers: nil,
      result_transformers: nil,
      errors_transformers: nil,
      pre_commit_transformers: nil,
      serializers: nil,
      allowed_rule: default_allowed_rule,
      requires_authentication: nil,
      authenticator: self.authenticator,
      aggregate_entities: nil
    )
      serializers = [*serializers, *default_serializers]
      pre_commit_transformers = [*pre_commit_transformers, *default_pre_commit_transformers]

      if aggregate_entities
        pre_commit_transformers << Foobara::CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer
        # TODO: Http should not appear at all in this project...
        serializers << Foobara::CommandConnectors::Http::Serializers::AggregateSerializer
      elsif aggregate_entities == false
        pre_commit_transformers.delete(Foobara::CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer)
        serializers.delete(Foobara::CommandConnectors::Http::Serializers::AggregateSerializer)
      end

      Foobara::TransformedCommand.subclass(
        command_class,
        capture_unknown_error:,
        inputs_transformers: [*inputs_transformers, *default_inputs_transformers],
        result_transformers: [*result_transformers, *default_result_transformers],
        errors_transformers: [*errors_transformers, *default_errors_transformers],
        pre_commit_transformers:,
        # TODO: maybe treat serializer as a result transformer instead??
        serializers:,
        # TODO: Maybe treat these three as a pre-execute validator??
        allowed_rule: allowed_rule && to_allowed_rule(allowed_rule),
        requires_authentication:,
        authenticator:
      )
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

    def default_pre_commit_transformers
      @default_pre_commit_transformers ||= []
    end

    def add_default_pre_commit_transformer(transformer)
      default_pre_commit_transformers << transformer
    end

    def default_serializers
      @default_serializers ||= []
    end

    def add_default_serializer(serializer)
      default_serializers << serializer
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

    def transformed_command_from_name(name)
      transformed_command_name, domain, org = name.to_s.split("::").reverse
      transformed_commands = short_name_to_transformed_command[transformed_command_name]

      if transformed_commands
        if transformed_commands.is_a?(::Array)
          transformed_commands = transformed_commands.select do |transformed_command|
            domain_org_match_transformed_command?(transformed_command, domain, org)
          end

          if transformed_commands.size > 1
            transformed_commands.find  { |transformed_command| transformed_command.domain.global? }
          else
            transformed_commands.first
          end
        elsif domain_org_match_transformed_command?(transformed_commands, domain, org)
          transformed_commands
        end
      end
    end

    def domain_org_match_transformed_command?(transformed_command, domain_name, org_name)
      dom = transformed_command.domain
      org = dom&.foobara_organization_name

      (org_name.nil? || org_name == org) && (domain_name.nil? || domain_name == dom&.foobara_domain_name)
    end
  end
end
