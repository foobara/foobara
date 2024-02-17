module Foobara
  class CommandRegistry
    include TruncatedInspect

    foobara_instances_are_namespaces!

    attr_accessor :authenticator, :default_allowed_rule

    def initialize(authenticator: nil)
      self.scoped_path = []
      self.authenticator = authenticator

      customized = %i[command domain organization]

      Foobara.foobara_categories.keys.reverse.each do |symbol|
        next if customized.include?(symbol)

        proc = Foobara.foobara_categories[symbol]

        foobara_add_category(symbol, &proc)
      end

      foobara_add_category_for_instance_of(:command, ExposedCommand)
      foobara_add_category_for_instance_of(:domain, ExposedDomain)
      foobara_add_category_for_instance_of(:organization, ExposedOrganization)
    end

    def register(command_class, **)
      create_exposed_command(command_class, **)
    end

    def create_exposed_command(command_class, **)
      full_domain_name = command_class.domain.scoped_full_name
      exposed_domain = foobara_lookup_domain(full_domain_name) || build_and_register_exposed_domain(full_domain_name)

      exposed_command = create_exposed_command_without_domain(command_class, **)

      exposed_domain.foobara_register(exposed_command)

      exposed_command
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
      # TODO: would be nice to not have to do this...
      domain_module = if domain_full_name.to_s == ""
                        GlobalDomain
                      else
                        Foobara.foobara_lookup_domain!(domain_full_name)
                      end

      full_organization_name = domain_module.foobara_full_organization_name
      exposed_organization = foobara_lookup_organization(full_organization_name) ||
                             build_and_register_exposed_organization(full_organization_name)

      exposed_domain = ExposedDomain.new(domain_module)

      exposed_organization.foobara_register(exposed_domain)
      exposed_domain.foobara_parent_namespace = exposed_organization

      exposed_domain
    end

    def build_and_register_exposed_organization(full_organization_name)
      org = if full_organization_name.to_s == ""
              GlobalOrganization
            else
              Foobara.foobara_lookup_organization!(full_organization_name)
            end

      exposed_organization = ExposedOrganization.new(org)
      foobara_register(exposed_organization)
      exposed_organization.foobara_parent_namespace = self

      exposed_organization
    end

    def exposed_global_domain
      exposed_global_organization.foobara_lookup_domain("") ||
        build_and_register_exposed_domain("")
    end

    def exposed_global_organization
      foobara_lookup_organization("") ||
        build_and_register_exposed_organization("")
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
      foobara_lookup_command(name)&.transformed_command_class
    end

    def all_transformed_command_classes
      foobara_all_command.map(&:transformed_command_class)
    end

    def each_transformed_command_class(&)
      foobara_all_command.map(&:transformed_command_class).each(&)
    end
  end
end
