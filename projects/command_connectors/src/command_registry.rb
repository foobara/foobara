module Foobara
  class CommandRegistry
    foobara_instances_are_namespaces!

    attr_accessor :authenticator, :default_allowed_rule

    def initialize(authenticator: nil)
      self.scoped_path = []
      self.authenticator = authenticator

      customized = %i[command domain organization]

      Foobara.foobara_categories.each_pair do |symbol, proc|
        next if customized.include?(symbol)

        foobara_add_category(symbol, &proc)
      end

      foobara_add_category_for_instance_of(:command, ExposedCommand)
      foobara_add_category_for_instance_of(:domain, ExposedDomain)
      foobara_add_category_for_instance_of(:organization, ExposedOrganization)
    end

    def register(command_class, **)
      exposed_command = create_exposed_command(command_class, **)

      foobara_register_command(exposed_command)

      exposed_command
    end

    def create_exposed_command(command_class, **opts)
      domain_full_name = command_class.domain.foobara_full_domain_name
      exposed_domain = foobara_lookup_domain(full_domain_name) || build_and_register_exposed_domain(domain_full_name)

      create_exposed_command_without_domain(**opts.merge(exposed_domain:))
    end

    # TODO: eliminate this method
    def create_exposed_command_without_domain(command_class, **)
      ExposedCommand.new(command_class, **apply_defaults(**))
    end

    def apply_defaults(
      inputs_transformers: nil,
      result_transformers: nil,
      errors_transformers: nil,
      pre_commit_transformers: nil,
      serializers: nil,
      allowed_rule: default_allowed_rule,
      authenticator: self.authenticator,
      **opts
    )
      opts.merge(
        inputs_transformers: [*inputs_transformers, *default_inputs_transformers],
        result_transformers: [*result_transformers, *default_result_transformers],
        errors_transformers: [*errors_transformers, *default_errors_transformers],
        pre_commit_transformers: [*pre_commit_transformers, *default_pre_commit_transformers],
        serializers: [*serializers, *default_serializers],
        allowed_rule: allowed_rule && to_allowed_rule(allowed_rule),
        authenticator:
      )
    end

    def build_and_register_exposed_domain(domain_full_name)
      domain_module = Foobara.foobara_lookup_domain!(domain_full_name)

      organization_full_name = command_class.full_organization_name
      exposed_organization = foobara_lookup_organization(organization_full_name) ||
                             build_and_register_exposed_organization(organization_full_name)

      exposed_domain = ExposedDomain.new(domain_module, exposed_organization:)

      foobara_register_domain(exposed_domain, registry: self)

      exposed_domain
    end

    def build_and_register_exposed_organization(organization_full_name)
      organization_module = Foobara.foobara_lookup_organization!(organization_full_name)
      exposed_organization = ExposedOrganization.new(organization_module)

      foobara_register_organization(exposed_organization)

      exposed_organization
    end

    def [](name)
      if name.is_a?(Class)
        name.full_command_name
      end

      foobara_lookup(name)
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
            # What are we doing here? Is this necessary?
            # I suppose the idea here is that if it's ambiguous we return the most unqualified of names.
            # Perhaps better to raise an exception?
            transformed_commands.find { |transformed_command| transformed_command.domain == GlobalDomain }
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

    def all_transformed_command_classes
      registry.values
    end

    def each_transformed_command_class(&)
      registry.each_value(&)
    end
  end
end
