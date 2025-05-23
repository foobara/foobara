module Foobara
  class CommandRegistry
    include TruncatedInspect

    foobara_instances_are_namespaces!

    attr_accessor :authenticator, :default_allowed_rule

    # Should we support different authenticators for different commands?
    # Might be a smell of two domains co-habitating in one? Or maybe one is just
    # passing another through and we should support that?
    def initialize(authenticator: nil)
      self.scoped_path = []
      self.authenticator = authenticator

      customized = [:command]

      Namespace.global.foobara_categories.keys.reverse.each do |symbol|
        next if customized.include?(symbol)

        proc = Namespace.global.foobara_categories[symbol]

        foobara_add_category(symbol, &proc)
      end

      foobara_add_category_for_instance_of(:command, ExposedCommand)

      foobara_depends_on_namespaces << Namespace.global
    end

    def register(command_class, **)
      create_exposed_command(command_class, **)
    end

    def create_exposed_command(command_class, **)
      full_domain_name = command_class.domain.scoped_full_name
      exposed_domain = foobara_lookup_domain(full_domain_name, mode: Namespace::LookupMode::ABSOLUTE) ||
                       build_and_register_exposed_domain(full_domain_name)

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
      authenticator: nil,
      **opts
    )
      opts.merge(
        inputs_transformers: [*inputs_transformers, *default_inputs_transformers],
        result_transformers: [*result_transformers, *default_result_transformers],
        errors_transformers: [*errors_transformers, *default_errors_transformers],
        pre_commit_transformers: [*pre_commit_transformers, *default_pre_commit_transformers],
        serializers: [*serializers, *default_serializers],
        allowed_rule: allowed_rule && to_allowed_rule(allowed_rule),
        authenticator: authenticator || self.authenticator
      )
    end

    def build_and_register_exposed_domain(domain_full_name)
      domain_module = if domain_full_name.to_s == ""
                        GlobalDomain
                      else
                        Namespace.global.foobara_lookup_domain!(domain_full_name)
                      end

      full_organization_name = domain_module.foobara_full_organization_name

      exposed_organization = foobara_lookup_organization(
        full_organization_name,
        mode: Namespace::LookupMode::ABSOLUTE
      ) || build_and_register_exposed_organization(full_organization_name)

      exposed_domain = Module.new
      exposed_domain.foobara_namespace!
      exposed_domain.foobara_domain!
      exposed_domain.extend(ExposedDomain)
      exposed_domain.unexposed_domain = domain_module

      exposed_domain.foobara_depends_on domain_module

      exposed_organization.foobara_register(exposed_domain)
      exposed_domain.foobara_parent_namespace = exposed_organization

      domain_module.foobara_depends_on.each do |domain_name|
        # TODO: test this code path!!
        # :nocov:
        unless foobara_domain_registered?(domain_name)
          build_and_register_exposed_domain(domain_name)
        end
        # :nocov:
      end

      exposed_domain
    end

    def global_domain
      foobara_lookup_domain("") || build_and_register_exposed_domain("")
    end

    def global_organization
      # TODO: test this
      # :nocov:
      foobara_lookup_organization("") || build_and_register_exposed_organization("")
      # :nocov:
    end

    def build_and_register_exposed_organization(full_organization_name)
      org = if full_organization_name.to_s == ""
              GlobalOrganization
            else
              Namespace.global.foobara_lookup_organization!(full_organization_name)
            end

      exposed_organization = Module.new
      exposed_organization.foobara_namespace!
      exposed_organization.foobara_organization!
      exposed_organization.extend(ExposedOrganization)
      exposed_organization.unexposed_organization = org

      foobara_register(exposed_organization)
      exposed_organization.foobara_parent_namespace = self

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

    def allowed_rule(*)
      allowed_rule = to_allowed_rule(*)

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

    def to_allowed_rule(*args)
      symbol, object = case args.size
                       when 1
                         [nil, args.first]
                       when 2
                         args
                       else
                         # :nocov:
                         raise ArgumentError, "Expected 1 or 2 arguments, got #{args.size}"
                         # :nocov:
                       end

      case object
      when AllowedRule, nil
        object
      when ::String
        if symbol
          # :nocov:
          raise ArgumentError, "Was not expecting a symbol and a string"
          # :nocov:
        end

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
          AllowedRule.new(symbol:, &object)
        else
          # :nocov:
          raise "Not sure how to convert #{object} into an AllowedRule object"
          # :nocov:
        end
      end.tap do |rule|
        rule.symbol ||= symbol
      end
    end

    def transformed_command_from_name(name)
      foobara_lookup_command(name, mode: Namespace::LookupMode::RELAXED)&.transformed_command_class
    end

    def all_transformed_command_classes
      foobara_all_command.map(&:transformed_command_class)
    end

    def each_transformed_command_class(&)
      foobara_all_command.map(&:transformed_command_class).each(&)
    end

    def size
      foobara_all_command.size
    end
  end
end
