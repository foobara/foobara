module Foobara
  class CommandConnector
    class UnexpectedSensitiveTypeInManifestError < StandardError; end
    class AlreadyConnectedError < StandardError; end

    include Concerns::Desugarizers
    include Concerns::Reflection

    class << self
      def find_builtin_command_class(command_class_name)
        Util.find_constant_through_class_hierarchy(self, "Commands::#{command_class_name}")
      end

      def allowed_rules_to_register
        return @allowed_rules_to_register if defined?(@allowed_rules_to_register)

        @allowed_rules_to_register = if superclass == Object
                                       []
                                     else
                                       superclass.allowed_rules_to_register.dup
                                     end
      end

      def register_allowed_rule(*rule_args)
        allowed_rules_to_register << rule_args
      end

      def authenticator_registry
        return @authenticator_registry if defined?(@authenticator_registry)

        @authenticator_registry = if superclass == Object
                                    {}
                                  else
                                    superclass.authenticator_registry.dup
                                  end
      end

      def register_authenticator(*authenticatorish_args)
        authenticator = to_authenticator(*authenticatorish_args)

        unless authenticator.symbol
          # simplecov:disable
          raise ArgumentError, "Expected authenticator to have a symbol"
          # simplecov:enable
        end

        authenticator_registry[authenticator.symbol] = authenticator
      end

      # TODO: relocate to Authenticator
      def to_authenticator(*args)
        symbol, object = case args.size
                         when 1
                           [nil, args[0]]
                         when 2
                           args
                         else
                           # simplecov:disable
                           raise ArgumentError, "Expected 1 or 2 arguments, got #{args.size}"
                           # simplecov:enable
                         end

        case object
        when Class
          if object < Authenticator
            object.instance
          else
            # simplecov:disable
            raise ArgumentError, "Expected a class that inherits from Authenticator"
            # simplecov:enable
          end
        when Authenticator, nil
          object
        when ::String
          if symbol
            # simplecov:disable
            raise ArgumentError, "Was not expecting a symbol and a string"
            # simplecov:enable
          end

          to_authenticator(object.to_sym)
        when ::Symbol
          authenticator = authenticator_registry[object]

          unless authenticator
            # simplecov:disable
            raise "No authenticator found for #{object}"
            # simplecov:enable
          end

          authenticator
        when ::Array
          case object.size
          when 0
            # TODO: test this
            # simplecov:disable
            nil
            # simplecov:enable
          when 1
            to_authenticator(object[0])
          else
            authenticators = object.map { |authenticatorish| to_authenticator(authenticatorish) }
            AuthenticatorSelector.new(authenticators:, symbol:)
          end
        else
          if object.respond_to?(:call)
            Authenticator.new(symbol:, &object)
          else
            # simplecov:disable
            raise "Not sure how to convert #{object} into an AllowedRule object"
            # simplecov:enable
          end
        end.tap do |resolved_authenticator|
          if resolved_authenticator
            resolved_authenticator.symbol ||= symbol
          end
        end
      end

      # don't call this auth_user ?
      def to_auth_user_mapper(object)
        case object
        when TypeDeclarations::TypedTransformer
          object
        when ::Class
          if object < TypeDeclarations::TypedTransformer
            object.instance
          elsif object < Foobara::DomainMapper
            build_auth_mapper(object.to_type) { |authenticated_user| object.map!(authenticated_user) }
          elsif object < Foobara::Command
            inputs_type = object.inputs_type
            element_types = inputs_type.element_types
            size = element_types.size

            first_required_input = if size == 1
                                     element_types.keys[0]
                                   elsif size > 1
                                     declaration = inputs_type&.declaration_data
                                     required_attribute_names = declaration&.[](:required) || EMPTY_ARRAY

                                     if required_attribute_names.size == 1
                                       required_attribute_names[0]
                                     else
                                       # simplecov:disable
                                       raise ArgumentError,
                                             "Ambiguous inputs when trying to use #{object} as a mapper. " \
                                             "Should have either only 1 input or only 1 required input."
                                       # simplecov:enable
                                     end
                                   else
                                     # simplecov:disable
                                     raise ArgumentError, "To use a command as a mapper it must take an input to map"
                                     # simplecov:enable
                                   end

            build_auth_mapper(object.result_type) do |authenticated_user|
              object.run!(first_required_input => authenticated_user)
            end
          else
            # simplecov:disable
            raise ArgumentError, "not sure how to convert a #{object} to an auth mapper"
            # simplecov:enable
          end
        when ::Hash
          object => { to:, map: }
          build_auth_mapper(to, &map)
        when ::Array
          object => [to, map]
          build_auth_mapper(to, &map)
        else
          # simplecov:disable
          raise ArgumentError, "Not sure how to convert #{object} to an auth mapper"
          # simplecov:enable
        end
      end

      # TODO: make private
      def build_auth_mapper(to_type, &)
        TypeDeclarations::TypedTransformer.subclass(to: to_type, &).instance
      end

      def always_allowed_rule
        # maybe move AllowedRule to CommandConnector:: instead of
        # CommandRegistry:: which is more of an implementation detail?
        @always_allowed_rule ||= CommandRegistry::AllowedRule.new(
          symbol: :always,
          explanation: "This always passes. Used to override allowed_rule_missing."
        ) { true }
      end
    end

    attr_accessor :command_registry, :authenticator, :capture_unknown_error, :name,
                  :auth_map, :requires_allowed_rule

    def initialize(name: nil,
                   authenticator: nil,
                   capture_unknown_error: nil,
                   default_serializers: nil,
                   default_pre_commit_transformers: nil,
                   auth_map: nil,
                   current_user: nil,
                   # TODO: let's default this to true
                   requires_allowed_rule: false,
                   allowed_rules: nil,
                   allow: nil,
                   &block)
      authenticator = self.class.to_authenticator(authenticator)

      if current_user
        auth_map ||= {}
        auth_map[:current_user] = current_user
      end

      if auth_map
        self.auth_map = auth_map.transform_values do |mapper|
          self.class.to_auth_user_mapper(mapper)
        end
      end

      self.authenticator = authenticator
      self.command_registry = CommandRegistry.new(authenticator:)
      allowed_rules&.each_pair { |symbol, rule| register_allowed_rule(symbol, rule) }
      self.allow allow if allow

      self.capture_unknown_error = capture_unknown_error
      self.name = name

      Util.array(default_serializers).each do |serializer|
        add_default_serializer(serializer)
      end

      if requires_allowed_rule
        self.requires_allowed_rule = requires_allowed_rule
        register_allowed_rule(CommandConnector.always_allowed_rule)
      end

      Util.array(default_pre_commit_transformers).each do |pre_commit_transformer|
        add_default_pre_commit_transformer(pre_commit_transformer)
      end

      self.class.allowed_rules_to_register.each do |ruleish_args|
        command_registry.allowed_rule(*ruleish_args)
      end

      if block
        instance_eval(&block)
      end
    end

    def allow(rules)
      command_registry.allow rules
    end

    def register_allowed_rule(*ruleish_args)
      command_registry.allowed_rule(*ruleish_args)
    end

    # TODO: should this be the official way to connect a command instead of #connect ?
    # Probably not. But what about #export instead?
    def command(...) = connect(...)

    def connect(*args, **opts)
      args, opts = desugarize_connect_args(args, opts)

      registerable = args[0]

      if opts.key?(:authenticator)
        authenticator = opts[:authenticator]
        authenticator = self.class.to_authenticator(authenticator)
        opts = opts.merge(authenticator:)
      end

      case registerable
      when Class
        unless registerable < Command
          # simplecov:disable
          raise "Don't know how to register #{registerable} (#{registerable.class})"
          # simplecov:enable
        end

        command_registry.register(*args, **opts)
      when Module
        if registerable.foobara_organization?
          args = args[1..]
          registerable.foobara_domains.map do |domain|
            connect(domain, *args, **opts)
          end.flatten
        elsif registerable.foobara_domain?
          args = args[1..]
          connected = []

          registerable = registerable.foobara_all_command(mode: Namespace::LookupMode::DIRECT)

          registerable.each do |command_class|
            unless command_class.abstract?
              connected << connect(command_class, *args, **opts)
            end
          end

          connected.flatten
        else
          # simplecov:disable
          raise "Don't know how to register #{registerable} (#{registerable.class})"
          # simplecov:enable
        end
      when Symbol, String
        connect_delayed(*args, **opts)
      else
        # simplecov:disable
        raise "Don't know how to register #{registerable} (#{registerable.class})"
        # simplecov:enable
      end
    end

    # TODO: maybe introduce a Runner interface?
    def run(...)
      process_delayed_connections

      request = build_request(...)

      run_request(request)
    end

    def find_builtin_command_class(command_class_name)
      self.class.find_builtin_command_class(command_class_name)
    end

    def add_default_inputs_transformer(transformer)
      command_registry.add_default_inputs_transformer(transformer)
    end

    def add_default_result_transformer(transformer)
      command_registry.add_default_result_transformer(transformer)
    end

    def add_default_errors_transformer(transformer)
      command_registry.add_default_errors_transformer(transformer)
    end

    def add_default_pre_commit_transformer(transformer)
      command_registry.add_default_pre_commit_transformer(transformer)
    end

    def add_default_serializer(serializer)
      command_registry.add_default_serializer(serializer)
    end

    def add_default_response_mutator(mutator)
      # simplecov:disable
      command_registry.add_default_response_mutator(mutator)
      # simplecov:enable
    end

    def allowed_rule(*)
      # simplecov:disable
      command_registry.allowed_rule(*)
      # simplecov:enable
    end

    def allowed_rules(*)
      command_registry.allowed_rules(*)
    end

    def transformed_command_from_name(*)
      command_registry.transformed_command_from_name(*)
    end

    def each_transformed_command_class(&)
      # simplecov:disable
      command_registry.each_transformed_command_class(&)
      # simplecov:enable
    end

    def all_transformed_command_classes
      command_registry.all_transformed_command_classes
    end

    def lookup_command(name)
      command_registry.foobara_lookup_command(name)
    end

    def type_from_name(name)
      Foobara.foobara_lookup_type(name, mode: Namespace::LookupMode::RELAXED)
    end

    def all_exposed_commands
      process_delayed_connections

      command_registry.foobara_all_command(mode: Namespace::LookupMode::ABSOLUTE_SINGLE_NAMESPACE)
    end

    def all_exposed_command_names
      all_exposed_commands.map(&:full_command_name)
    end

    def command_connected?(original_command_class)
      all_exposed_commands.any? do |command|
        command.command_class == original_command_class
      end
    end

    protected

    def request_to_command_class(request)
      action = request.action
      full_command_name = request.full_command_name

      if action == "run"
        transformed_command_class = transformed_command_from_name(full_command_name)

        unless transformed_command_class
          # simplecov:disable
          raise NoCommandFoundError.new(message: "Could not find command registered for #{full_command_name}")
          # simplecov:enable
        end
      else
        action = case action
                 when "describe_type", "manifest", "describe_command"
                   "describe"
                 when "describe", "ping", "query_git_commit_info", "help"
                   action
                 when "list"
                   "list_commands"
                 else
                   # simplecov:disable
                   raise InvalidContextError.new(message: "Not sure what to do with #{action}")
                   # simplecov:enable
                 end

        command_name = Util.classify(action)
        command_class = find_builtin_command_class(command_name)
        full_command_name = command_class.full_command_name

        transformed_command_class = transformed_command_from_name(full_command_name) ||
                                    transform_command_class(command_class)

        if transformed_command_class < TransformedCommand
          transformed_command_class.builtin = true
        end
      end

      transformed_command_class
    end

    def request_to_command_inputs(request)
      action = request.action
      full_command_name = request.full_command_name

      case action
      when "run"
        request.inputs
      when "describe"
        manifestable_name = full_command_name || request.inputs[:manifestable]
        manifestable = if manifestable_name
                         transformed_command_from_name(manifestable_name) || type_from_name(manifestable_name)
                       end

        unless manifestable
          # simplecov:disable
          raise NoCommandOrTypeFoundError.new(
            message: "Could not find command or type registered for #{manifestable_name}"
          )
          # simplecov:enable
        end

        request.inputs.merge(manifestable:, request:)
      when "describe_command"
        transformed_command_class = transformed_command_from_name(full_command_name)

        unless transformed_command_class
          # simplecov:disable
          raise NoCommandFoundError.new(message: "Could not find command registered for #{full_command_name}")
          # simplecov:enable
        end

        request.inputs.merge(manifestable: transformed_command_class, request:)
      when "describe_type"
        type = type_from_name(full_command_name)

        unless type
          # simplecov:disable
          raise NoTypeFoundError.new(message: "Could not find type registered for #{full_command_name}")
          # simplecov:enable
        end

        request.inputs.merge(manifestable: type, request:)
      when "manifest"
        request.inputs.merge(manifestable: self, request:)
      when "ping", "query_git_commit_info"
        nil
      when "help"
        { request: }
      when "list"
        request.inputs.merge(request:)
      else
        # simplecov:disable
        raise InvalidContextError.new(message: "Not sure what to do with #{action}")
        # simplecov:enable
      end
    end

    def request_to_command_instance(request)
      command_class = request.command_class
      inputs = request.inputs

      if inputs && !inputs.empty?
        command_class.new(inputs)
      else
        command_class.new
      end
    end

    # Feels like we should just register these if we're going to make use of them via "actions"...
    # TODO: figure out how to kill this
    def transform_command_class(klass)
      command_registry.create_exposed_command_without_domain(klass).transformed_command_class
    end

    def request_to_response(request)
      response = self.class::Response.new(request:)
      request.response = response
      response
    end

    def set_response_status(response)
      response.status = response.success? ? 0 : 1
    end

    def set_response_body(response)
      outcome = response.request.outcome
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
        # TODO: Get serialization off of the command instance!!
        response.body = command.serialize_result(response.body)
      end
    end

    def connect_delayed(registerable_name, *args, **opts)
      key = registerable_name.to_s

      if delayed_connections.key?(key)
        # simplecov:disable
        raise AlreadyConnectedError, "Already connected #{key}"
        # simplecov:enable
      else
        delayed_connections[key] = { args:, opts: }
      end
    end

    def delayed_connections
      @delayed_connections ||= {}
    end

    def process_delayed_connections
      return if delayed_connections.empty?

      delayed_connections.each_pair do |registerable_name, arg_hash|
        args = arg_hash[:args]
        opts = arg_hash[:opts]

        const = Object.const_get(registerable_name)
        connect(const, *args, **opts)
      end

      delayed_connections.clear
    end

    def desugarize_connect_args(args, opts)
      if self.class.desugarizer
        self.class.desugarizer.process_value!([args, opts])
      else
        # TODO: test this code path by removing all desugarizers in a spec.
        # simplecov:disable
        [args, opts]
        # simplecov:enable
      end
    end

    def build_request(...)
      self.class::Request.new(...).tap do |request|
        # TODO: feels like a smell? Can we deprecate this somehow? Request no longer calls command_connector it seems...
        request.command_connector = self
      end
    end

    # TODO: get all this persistence stuff out of here and into entities plumbing somehow
    def run_request(request)
      command_class = determine_command_class(request)
      request.command_class = command_class

      if request.requires_authentication?
        request.authenticator ||= command_class.authenticator || authenticator

        if auth_map
          request.auth_mappers ||= auth_map
        end
      end

      return build_response(request) unless command_class

      begin
        request.open_transaction
        request.use_transaction do
          request.authenticate
          request.mutate_request

          inputs = request_to_command_inputs(request)
          request.inputs = inputs
          command = build_command_instance(request)
          request.command = command

          unless request.error
            if command
              run_command(request)
              # simplecov:disable
            else
              raise "No command returned from #request_to_command"
              # simplecov:enable
            end
          end
        end
      ensure
        if (request.response || request).outcome&.success?
          request.commit_transaction_if_open
        else
          request.rollback_transaction
        end
      end

      build_response(request)
    end

    def run_command(request)
      command = request.command
      command_class = request.command_class

      if requires_allowed_rule &&
         command.is_a?(TransformedCommand) &&
         # The != false looks odd and must be that we want to distinguish between the default (nil)
         # and explicitly not requiring auth
         command.class.requires_authentication != false &&
         !command_class.builtin?
        unless command.allowed_rule
          raise NoAllowedRuleGivenError,
                "Must connect #{command.full_command_name} with an `allowed_if:` " \
                "because `requires_allowed_rule` is true. You can use `allow_if: :always` if want to always allow " \
                "this command to be ran or you can also use `requires_allowed_rule: false` " \
                "when creating the connector if you don't want to enforce allowed_if: for all connected commands."
        end
      end

      unless command.outcome
        command.run
      end
    rescue => e
      if capture_unknown_error
        request.error = CommandConnector::UnknownError.for(e)
      else
        raise
      end
    end

    def build_command_instance(request)
      command = request_to_command_instance(request)
      request.command = command
      if command.is_a?(TransformedCommand)
        # This allows the command to access the authenticated_user
        command.request = request
      end

      command
    end

    def determine_command_class(request)
      unless request.error
        command_class = request_to_command_class(request)
        request.command_class = command_class
      end
    end

    def build_response(request)
      response = request_to_response(request)

      set_response_status(response)
      set_response_body(response)
      mutate_response(response)
      serialize_response_body(response)

      response
    end
  end
end
