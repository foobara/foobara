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

    class NotFoundError < CommandConnectorError
      class << self
        def context_type_declaration
          { not_found: :string }
        end
      end

      attr_accessor :not_found

      def initialize(not_found)
        self.not_found = not_found

        super(message, context: { not_found: })
      end

      def message
        "Not found: #{not_found}"
      end
    end

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
                     :each_transformed_command_class,
                     :all_transformed_command_classes,
                     to: :command_registry

    attr_accessor :command_registry, :authenticator

    def lookup_command(name)
      command_registry.foobara_lookup_command(name)
    end

    # TODO: maybe instead connect commands with a shortcut_only: "describe" option
    # in order to make this easier to extend and manage.
    def request_to_command(request)
      action = request.action
      inputs = nil
      full_command_name = request.full_command_name

      case action
      when "run"
        transformed_command_class = transformed_command_from_name(full_command_name)

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

        command_class = self.class::Commands::Describe
        full_command_name = command_class.full_command_name

        inputs = { manifestable:, request: }
        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "describe_command"
        transformed_command_class = transformed_command_from_name(full_command_name)

        unless transformed_command_class
          # :nocov:
          raise NoCommandFoundError, "Could not find command registered for #{full_command_name}"
          # :nocov:
        end

        command_class = self.class::Commands::Describe
        full_command_name = command_class.full_command_name

        inputs = { manifestable: transformed_command_class, request: }
        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "describe_type"
        type = type_from_name(full_command_name)

        unless type
          # :nocov:
          raise NoTypeFoundError, "Could not find type registered for #{full_command_name}"
          # :nocov:
        end

        command_class = self.class::Commands::Describe
        full_command_name = command_class.full_command_name

        inputs = { manifestable: type, request: }
        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "manifest"
        command_class = self.class::Commands::Describe
        full_command_name = command_class.full_command_name

        inputs = { manifestable: self, request: }
        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "ping"
        command_class = Foobara::CommandConnectors::Commands::Ping
        full_command_name = command_class.full_command_name

        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "query_git_commit_info"
        # TODO: this feels out of control... should just accomplish this through run I think instead. Same with ping.
        command_class = Foobara::CommandConnectors::Commands::QueryGitCommitInfo
        full_command_name = command_class.full_command_name

        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "help"
        command_class = self.class::Commands::Help
        full_command_name = command_class.full_command_name

        inputs = { request: }
        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "list"
        mod = self.class::Commands
        command_class = if mod.const_defined?(:ListCommands)
                          # TODO: test this
                          # :nocov:
                          mod::ListCommands
                          # :nocov:
                        else
                          CommandConnectors::Commands::ListCommands
                        end

        full_command_name = command_class.full_command_name

        request.command_class = command_class
        inputs = request.inputs.merge(request:)

        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      else
        # :nocov:
        raise InvalidContextError, "Not sure what to do with #{action}"
        # :nocov:
      end

      if inputs && !inputs.empty?
        transformed_command_class.new(inputs)
      else
        transformed_command_class.new
      end
    end

    # Feels like we should just register these if we're going to make use of them via "actions"...
    # TODO: figure out how to kill this
    def transform_command_class(klass)
      command_registry.create_exposed_command_without_domain(klass).transformed_command_class
    end

    def request_to_response(_command)
      # :nocov:
      raise "subclass responsibility"
      # :nocov:
    end

    def initialize(authenticator: nil, default_serializers: nil)
      self.command_registry = CommandRegistry.new(authenticator:)
      self.authenticator = authenticator

      Util.array(default_serializers).each do |serializer|
        add_default_serializer(serializer)
      end
    end

    def connect(registerable, *, **)
      case registerable
      when Class
        unless registerable < Command
          # :nocov:
          raise "Don't know how to register #{registerable} (#{registerable.class})"
          # :nocov:
        end

        command_registry.register(registerable, *, **)
      when Module
        if registerable.foobara_organization?
          registerable.foobara_domains.map do |domain|
            connect(domain, *, **)
          end.flatten
        elsif registerable.foobara_domain?
          registerable.foobara_all_command(mode: Namespace::LookupMode::DIRECT).map do |command_class|
            Util.array(connect(command_class, *, **))
          end.flatten
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

    def build_request(...)
      self.class::Request.new(...)
    end

    # TODO: maybe introduce a Runner interface?
    def run(*, **)
      request, command = build_request_and_command(*, **)

      # TODO: feels like a smell
      request.command_connector = self

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

    def type_from_name(name)
      Foobara.foobara_lookup_type(name, mode: Namespace::LookupMode::RELAXED)
    end

    def foobara_manifest
      # Drive all of this off of the list of exposed commands...
      to_include = Set.new
      to_include << command_registry.exposed_global_organization
      to_include << command_registry.exposed_global_domain

      command_registry.foobara_each do |exposed_whatever|
        to_include << exposed_whatever
      end

      included = Set.new
      additional_to_include = Set.new

      h = {
        organization: {},
        domain: {},
        type: {},
        command: {},
        error: {},
        processor: {},
        processor_class: {}
      }

      until to_include.empty? && additional_to_include.empty?
        object = nil

        if to_include.empty?
          until additional_to_include.empty?
            o = additional_to_include.first
            additional_to_include.delete(o)

            if o.is_a?(::Module)
              if o.foobara_domain? || o.foobara_organization? || (o.is_a?(::Class) && o < Foobara::Command)
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

        category_symbol = command_registry.foobara_category_symbol_for(object)

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

      h[:domain].each_value do |domain_manifest|
        # TODO: hack, we need to trim types down to what is actually included in this manifest
        domain_manifest[:types] = domain_manifest[:types].select do |type_name|
          h[:type].key?(type_name.to_sym)
        end
      end

      normalize_manifest(h)
    end

    def normalize_manifest(manifest_hash)
      manifest_hash.map do |key, entries|
        [key, entries.sort.to_h]
      end.sort.to_h
    end

    def all_exposed_commands
      command_registry.foobara_all_command
    end
  end
end
