module Foobara
  class CommandConnector
    class CommandConnectorError < Foobara::RuntimeError
      class << self
        def context_type_declaration
          {}
        end
      end

      def initialize(message, context: {})
        super(message:, context:)
      end
    end

    class UnknownError < CommandConnectorError
      attr_accessor :error

      def initialize(error)
        # TODO: can we just use #cause for this?
        self.error = error

        super(error.message)
      end
    end

    class NotFoundError < CommandConnectorError; end

    class UnauthenticatedError < CommandConnectorError
      def initialize
        super("Unauthenticated")
      end
    end

    class NotAllowedError < CommandConnectorError
      class << self
        def context_type_declaration
          {
            rule_symbol: :symbol,
            explanation: :string
          }
        end
      end

      attr_accessor :rule_symbol, :explanation

      def initialize(rule_symbol:, explanation:)
        self.rule_symbol = rule_symbol || :no_symbol_declared
        self.explanation = explanation || "No explanation"

        super("Not allowed: #{explanation}", context:)
      end

      def context
        { rule_symbol:, explanation: }
      end
    end

    class InvalidContextError < CommandConnectorError; end
    class NoCommandFoundError < NotFoundError; end
    class NoTypeFoundError < NotFoundError; end
    class NoCommandOrTypeFoundError < NotFoundError; end

    foobara_delegate :add_default_inputs_transformer,
                     :add_default_result_transformer,
                     :add_default_errors_transformer,
                     :add_default_pre_commit_transformer,
                     :add_default_serializer,
                     :allowed_rule,
                     :allowed_rules,
                     :transform_command_class,
                     :transformed_command_from_name,
                     to: :command_registry

    attr_accessor :command_registry, :authenticator

    def initialize(authenticator: nil, default_serializers: nil)
      self.authenticator = authenticator
      self.command_registry = CommandRegistry.new(authenticator:)

      Util.array(default_serializers).each do |serializer|
        add_default_serializer(serializer)
      end
    end

    def connect(...)
      command_registry.register(...)
    end

    def build_request(...)
      self.class::Request.new(...)
    end

    def context_to_request(_context)
      # :nocov:
      raise "subclass responsibility"
      # :nocov:
    end

    def run(...)
      request = build_request(...)
      command = request_to_command(request)
      command.run
      command_to_response(command)
    end

    def registered_types_depended_on
      @registered_types_depended_on ||= begin
        types_depended_on = Set.new

        # TODO: should group by org and domain...
        command_registry.registry.each_value do |transformed_command_class|
          types_depended_on |= transformed_command_class.types_depended_on
        end

        # TODO: does this play nicely with types with same symbol in different namespaces??
        types_depended_on.select(&:registered?)
      end
    end

    def registered_types_depended_on_by_symbol
      @registered_types_depended_on_by_symbol ||= registered_types_depended_on.group_by(&:type_symbol).to_h do |k, v|
        if v.size == 1
          [k, v.first]
        else
          [k, v]
        end
      end
    end

    # TODO: relocate these methods into namespace or type registry or somewhere other than here
    def type_from_name(name)
      type_name, domain, org = name.to_s.split("::").reverse
      types = registered_types_depended_on_by_symbol[type_name.to_sym]

      if types
        if types.is_a?(::Array)
          types = types.select { |type| domain_org_match_type?(type, domain, org) }

          if types.size > 1
            # What are we doing here?
            types.find  { |type| Domain.to_domain(type) == GlobalDomain }
          else
            types.first
          end
        elsif domain_org_match_type?(types, domain, org)
          types
        end
      end
    end

    def domain_org_match_type?(type, domain_name, org_name)
      dom = Domain.to_domain(type)

      (org_name.nil? || org_name == dom&.foobara_organization_name) &&
        (domain_name.nil? || domain_name == dom&.foobara_domain_name)
    end

    def manifest
      # TODO: why is this so much more complex than Foobara.manifest??
      # I suppose because there's no transformed org/dom concept??
      # TODO: implement that
      organizations = {}
      h = { organizations: }

      domains = command_registry.registry.values.map(&:domain) +
                registered_types_depended_on.map { |type| Domain.to_domain(type) }.compact

      domains.compact!
      domains.uniq!

      domains.each do |domain|
        organization_name = domain.foobara_organization_name
        domain_name = domain.foobara_domain_name

        org = organizations[organization_name.to_sym] ||= { organization_name:, domains: {} }
        domains_h = org[:domains]

        domains_h[domain_name.to_sym] ||= domain.foobara_manifest(skip: %i[types commands]).merge(types: {},
                                                                                                  commands: {})
      end

      command_manifests = command_registry.registry.values.map(&:manifest)

      command_manifests.each do |command_manifest|
        org = command_manifest[:organization_name].to_sym
        dom = command_manifest[:domain_name].to_sym
        command_name = command_manifest[:command_name].to_sym

        organizations[org][:domains][dom][:commands][command_name] = command_manifest
      end

      registered_types_depended_on.each do |type|
        domain = Domain.to_domain(type)

        domain.foobara_type_namespace.use do
          org = domain.foobara_organization_name.to_sym
          dom = domain.foobara_domain_name.to_sym

          organizations[org][:domains][dom][:types][type.type_symbol] = type.manifest
        end
      end

      h
    end
  end
end
