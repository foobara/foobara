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

    def request_to_command(request)
      action = request.action
      inputs = nil
      full_command_name = request.full_command_name

      case action
      when "run"
        transformed_command_class = command_registry[full_command_name]

        unless transformed_command_class
          # :nocov:
          raise NoCommandFoundError, "Could not find command registered for #{full_command_name}"
          # :nocov:
        end

        request.command_class = transformed_command_class

        inputs = request.inputs
      when "describe"
        manifestable = transformed_command_from_name(full_command_name) || type_from_name(full_command_name)

        unless manifestable
          # :nocov:
          raise NoCommandOrTypeFoundError, "Could not find command or type registered for #{full_command_name}"
          # :nocov:
        end

        command_class = Foobara::CommandConnectors::Commands::Describe
        full_command_name = command_class.full_command_name

        inputs = { manifestable: }
        transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
      when "describe_command"
        transformed_command_class = transformed_command_from_name(full_command_name)

        unless transformed_command_class
          # :nocov:
          raise NoCommandFoundError, "Could not find command registered for #{full_command_name}"
          # :nocov:
        end

        command_class = Foobara::CommandConnectors::Commands::Describe
        full_command_name = command_class.full_command_name

        inputs = { manifestable: transformed_command_class }
        transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
      when "describe_type"
        type = type_from_name(full_command_name)

        unless type
          # :nocov:
          raise NoTypeFoundError, "Could not find type registered for #{full_command_name}"
          # :nocov:
        end

        command_class = Foobara::CommandConnectors::Commands::Describe
        full_command_name = command_class.full_command_name

        inputs = { manifestable: type }
        transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
      when "manifest"
        command_class = Foobara::CommandConnectors::Commands::Describe
        full_command_name = command_class.full_command_name

        inputs = { manifestable: self }
        transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
      when "ping"
        command_class = Foobara::CommandConnectors::Commands::Ping
        full_command_name = command_class.full_command_name

        transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
      when "query_git_commit_info"
        # TODO: this feels out of control... should just accomplish this through run I think instead. Same with ping.
        command_class = Foobara::CommandConnectors::Commands::QueryGitCommitInfo
        full_command_name = command_class.full_command_name

        transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
      else
        # :nocov:
        raise InvalidContextError, "Not sure what to do with #{action}"
        # :nocov:
      end

      transformed_command_class.new(inputs)
    end

    def request_to_response(_command)
      # :nocov:
      raise "subclass responsibility"
      # :nocov:
    end

    def initialize(authenticator: nil, default_serializers: nil)
      self.command_registry = CommandRegistry.new(authenticator:)
      self.authenticator = authenticator

      add_default_errors_transformer(Foobara::CommandConnectors::Transformers::AuthErrorsTransformer)

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

    def run(...)
      request, command = build_request_and_command(...)

      if command
        command.run
        # :nocov:
      elsif !request.error
        raise "No command returned from #request_to_command"
        # :nocov:
      end

      build_response(request)
    end

    def build_request_and_command(...)
      request = build_request(...)

      unless request.error
        command = request_to_command(request)
        request.command = command
      end

      [request, command]
    end

    def build_response(request)
      response = request_to_response(request)
      response.request = request
      response
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

    # TODO: break this method up and/or come up with more abstract ways to transform domains...
    def foobara_manifest
      # Drive all of this off of the list of exposed commands...
      to_include = Set.new
      domains = Set.new
      organizations = Set.new
      included_command_references = Set.new

      command_registry.registry.each_value do |transformed_command_class|
        included_command_references << transformed_command_class.foobara_manifest_reference
        to_include << transformed_command_class
        domains << transformed_command_class.domain
        organizations << transformed_command_class.organization
      end

      included = Set.new
      additional_to_include = Set.new

      h = { domain: {}, organization: {} }

      until to_include.empty? && additional_to_include.empty?
        object = nil

        if to_include.empty?
          until additional_to_include.empty?
            o = additional_to_include.first
            additional_to_include.delete(o)

            if o.is_a?(::Module)
              if o.foobara_domain?
                domains << o
                next
              elsif o.foobara_organization?
                organizations << o
                next
              elsif o.is_a?(::Class) && o < Foobara::Command
                # TODO: will this work just fine if the command is a sub command with errors??
                # TODO: ^ test that
                next
              end
            end

            object = o
            break
          end
        else
          object = to_include.first
          to_include.delete(object)
        end

        break unless object
        next if included.include?(object)

        manifest_reference = object.foobara_manifest_reference.to_sym

        category_symbol = if object.is_a?(::Class) && object < Foobara::TransformedCommand
                            :command
                          else
                            Foobara.foobara_category_symbol_for(object)
                          end

        raise "no category symbol for #{object}" unless category_symbol

        namespace = if object.is_a?(Types::Type)
                      object.created_in_namespace
                    else
                      Foobara::Namespace.current
                    end

        cat = h[category_symbol] ||= {}
        # TODO: do we really need to enter the namespace here for this?
        cat[manifest_reference] = Foobara::Namespace.use namespace do
          object.foobara_manifest(to_include: additional_to_include)
        end

        included << object
      end

      domains.each do |domain|
        organizations << domain.foobara_organization

        domain_manifest = domain.foobara_manifest(to_include: Set.new)

        # TODO: we need to trim types and commands...
        domain_manifest[:types] = domain_manifest[:types].select do |type_name|
          type = domain.foobara_lookup_type!(type_name)
          included.include?(type)
        end

        domain_manifest[:commands] = domain_manifest[:commands].select do |command_name|
          command = domain.foobara_lookup_command!(command_name)
          included_command_references.include?(command.foobara_manifest_reference)
        end

        h[:domain][domain.foobara_manifest_reference.to_sym] = domain_manifest

        included << domain
      end

      organizations.each do |organization|
        organization_manifest = organization.foobara_manifest(to_include: Set.new)

        organization_manifest[:domains] = organization_manifest[:domains].select do |domain_name|
          domain = if domain_name == "global_organization::global_domain"
                     GlobalDomain
                   else
                     organization.foobara_lookup_domain!(domain_name)
                   end
          included.include?(domain)
        end

        h[:organization][organization.foobara_manifest_reference.to_sym] = organization_manifest

        included << organization
      end

      h
    end
  end
end
