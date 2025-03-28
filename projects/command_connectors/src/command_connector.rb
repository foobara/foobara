module Foobara
  class CommandConnector
    class UnexpectedSensitiveTypeInManifestError < StandardError; end

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

    class << self
      def find_builtin_command_class(command_class_name)
        Util.find_constant_through_class_hierarchy(self, "Commands::#{command_class_name}")
      end
    end

    def find_builtin_command_class(command_class_name)
      self.class.find_builtin_command_class(command_class_name)
    end

    foobara_delegate :add_default_inputs_transformer,
                     :add_default_result_transformer,
                     :add_default_errors_transformer,
                     :add_default_pre_commit_transformer,
                     :add_default_serializer,
                     :add_default_response_mutator,
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

        command_class = find_builtin_command_class("Describe")
        full_command_name = command_class.full_command_name

        inputs = request.inputs.merge(manifestable:, request:)

        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "describe_command"
        transformed_command_class = transformed_command_from_name(full_command_name)

        unless transformed_command_class
          # :nocov:
          raise NoCommandFoundError, "Could not find command registered for #{full_command_name}"
          # :nocov:
        end

        command_class = find_builtin_command_class("Describe")
        full_command_name = command_class.full_command_name

        inputs = request.inputs.merge(manifestable: transformed_command_class, request:)
        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "describe_type"
        type = type_from_name(full_command_name)

        unless type
          # :nocov:
          raise NoTypeFoundError, "Could not find type registered for #{full_command_name}"
          # :nocov:
        end

        command_class = find_builtin_command_class("Describe")
        full_command_name = command_class.full_command_name

        inputs = request.inputs.merge(manifestable: type, request:)
        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "manifest"
        command_class = find_builtin_command_class("Describe")
        full_command_name = command_class.full_command_name

        inputs = request.inputs.merge(manifestable: self, request:)
        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "ping"
        command_class = find_builtin_command_class("Ping")
        full_command_name = command_class.full_command_name

        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "query_git_commit_info"
        # TODO: this feels out of control... should just accomplish this through run I think instead. Same with ping.
        command_class = find_builtin_command_class("QueryGitCommitInfo")
        full_command_name = command_class.full_command_name

        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "help"
        command_class = find_builtin_command_class("Help")
        full_command_name = command_class.full_command_name

        inputs = { request: }
        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)
      when "list"
        command_class = find_builtin_command_class("ListCommands")

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

    def request_to_response(request)
      self.class::Response.new(request:)
    end

    def set_response_status(response)
      outcome = response.request.outcome
      response.status = outcome.success? ? 0 : 1
    end

    def set_response_body(response)
      outcome = response.request.outcome
      # response.body = outcome.success? ? outcome.result : outcome.error_collection
      response.body = outcome.success? ? outcome.result : outcome.error_collection
    end

    def mutate_response(response)
      command = response.command

      if command.respond_to?(:mutate_response)
        command.mutate_response(response)
      end
    end

    def serialize_response_body(response)
      command = response.command

      if command.respond_to?(:serialize_result)
        response.body = command.serialize_result(response.body)
      end
    end

    def initialize(authenticator: nil, default_serializers: nil)
      self.command_registry = CommandRegistry.new(authenticator:)
      self.authenticator = authenticator

      Util.array(default_serializers).each do |serializer|
        add_default_serializer(serializer)
      end
    end

    def connect_delayed(registerable_name, *args, **opts)
      delayed_connections[registerable_name] = { args:, opts: }
    end

    def delayed_connections
      @delayed_connections ||= {}
    end

    def process_delayed_connections
      delayed_connections.each_pair do |registerable_name, arg_hash|
        args = arg_hash[:args]
        opts = arg_hash[:opts]

        const = Object.const_get(registerable_name)
        connect(const, *args, **opts)
      end

      delayed_connections.clear
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
      when Symbol, String
        connect_delayed(registerable, *, **)
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
      process_delayed_connections

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

      set_response_status(response)
      set_response_body(response)
      mutate_response(response)
      serialize_response_body(response)

      response
    end

    def type_from_name(name)
      Foobara.foobara_lookup_type(name, mode: Namespace::LookupMode::RELAXED)
    end

    def foobara_manifest(remove_sensitive: true)
      process_delayed_connections

      # Drive all of this off of the list of exposed commands...
      to_include = Set.new

      to_include << command_registry.global_organization
      to_include << command_registry.global_domain

      # ABSOLUTE lets us get all of the children but not include dependent domains (GlobalDomain)
      command_registry.foobara_each(mode: Namespace::LookupMode::ABSOLUTE) do |exposed_whatever|
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
              if o.foobara_domain? || o.foobara_organization?
                unless o.foobara_root_namespace == command_registry
                  next
                end
              elsif o.is_a?(::Class) && o < Foobara::Command
                next
              end
            elsif o.is_a?(Types::Type)
              if remove_sensitive && o.sensitive?
                # :nocov:
                raise UnexpectedSensitiveTypeInManifestError,
                      "Unexpected sensitive type in manifest: #{o.scoped_full_path}. Make sure these are not included."
              # :nocov:
              else
                domain_name = o.foobara_domain.scoped_full_name

                unless command_registry.foobara_registered?(domain_name)
                  domain = command_registry.build_and_register_exposed_domain(domain_name)
                  additional_to_include << domain
                  additional_to_include << domain.foobara_organization
                end
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

        unless category_symbol
          # :nocov:
          raise "no category symbol for #{object}"
          # :nocov:
        end

        namespace = if object.is_a?(Types::Type)
                      object.created_in_namespace
                    else
                      Foobara::Namespace.current
                    end

        cat = h[category_symbol] ||= {}
        # TODO: do we really need to enter the namespace here for this?
        cat[manifest_reference] = Foobara::Namespace.use namespace do
          object.foobara_manifest(to_include: additional_to_include, remove_sensitive:)
        end

        included << object
      end

      h[:domain].each_value do |domain_manifest|
        # TODO: hack, we need to trim types down to what is actually included in this manifest
        domain_manifest[:types] = domain_manifest[:types].select do |type_name|
          h[:type].key?(type_name.to_sym)
        end
      end

      h = normalize_manifest(h)

      patch_up_broken_parents_for_errors_with_missing_command_parents(h)
    end

    def normalize_manifest(manifest_hash)
      manifest_hash.map do |key, entries|
        [key, entries.sort.to_h]
      end.sort.to_h
    end

    def patch_up_broken_parents_for_errors_with_missing_command_parents(manifest_hash)
      root_manifest = Manifest::RootManifest.new(manifest_hash)

      error_category = {}

      root_manifest.errors.each do |error|
        error_manifest = if error.parent_category == :command &&
                            !root_manifest.contains?(error.parent_name, error.parent_category)
                           domain = error.domain
                           index = domain.scoped_full_path.size

                           fixed_scoped_path = error.scoped_full_path[index..]
                           fixed_scoped_name = fixed_scoped_path.join("::")
                           fixed_scoped_prefix = fixed_scoped_path[..-2]
                           fixed_parent = [:domain, domain.full_domain_name]

                           error.relevant_manifest.merge(
                             parent: fixed_parent,
                             scoped_path: fixed_scoped_path,
                             scoped_name: fixed_scoped_name,
                             scoped_prefix: fixed_scoped_prefix
                           )
                         else
                           error.relevant_manifest
                         end

        error_category[error.scoped_full_name.to_sym] = error_manifest
      end

      manifest_hash.merge(error: error_category)
    end

    def all_exposed_commands
      process_delayed_connections

      command_registry.foobara_all_command
    end
  end
end
