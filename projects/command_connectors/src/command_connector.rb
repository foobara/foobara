module Foobara
  class CommandConnector
    class UnexpectedSensitiveTypeInManifestError < StandardError; end

    include Concerns::Desugarizers

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
          # :nocov:
          raise ArgumentError, "Expected authenticator to have a symbol"
          # :nocov:
        end

        authenticator_registry[authenticator.symbol] = authenticator
      end

      # TODO: relocate to Authenticator
      def to_authenticator(*args)
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
        when Class
          if object < Authenticator
            object.new
          else
            # :nocov:
            raise ArgumentError, "Expected a class that inherits from Authenticator"
            # :nocov:
          end
        when Authenticator, nil
          object
        when ::String
          if symbol
            # :nocov:
            raise ArgumentError, "Was not expecting a symbol and a string"
            # :nocov:
          end

          to_authenticator(object.to_sym)
        when ::Symbol
          authenticator = authenticator_registry[object]

          unless authenticator
            # :nocov:
            raise "No authenticator found for #{object}"
            # :nocov:
          end

          authenticator
        when ::Array
          case object.size
          when 0
            # TODO: test this
            # :nocov:
            nil
            # :nocov:
          when 1
            to_authenticator(object.first)
          else
            authenticators = object.map { |authenticatorish| to_authenticator(authenticatorish) }
            AuthenticatorSelector.new(authenticators:, symbol:)
          end
        else
          if object.respond_to?(:call)
            Authenticator.new(symbol:, &object)
          else
            # :nocov:
            raise "Not sure how to convert #{object} into an AllowedRule object"
            # :nocov:
          end
        end.tap do |resolved_authenticator|
          if resolved_authenticator
            resolved_authenticator.symbol ||= symbol
          end
        end
      end
    end

    attr_accessor :command_registry, :authenticator, :capture_unknown_error, :name

    def initialize(name: nil,
                   authenticator: nil,
                   capture_unknown_error: nil,
                   default_serializers: nil,
                   default_pre_commit_transformers: nil)
      authenticator = self.class.to_authenticator(authenticator)

      self.authenticator = authenticator
      self.command_registry = CommandRegistry.new(authenticator:)
      self.capture_unknown_error = capture_unknown_error
      self.name = name

      Util.array(default_serializers).each do |serializer|
        add_default_serializer(serializer)
      end

      Util.array(default_pre_commit_transformers).each do |pre_commit_transformer|
        add_default_pre_commit_transformer(pre_commit_transformer)
      end

      self.class.allowed_rules_to_register.each do |ruleish_args|
        command_registry.allowed_rule(*ruleish_args)
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

    def lookup_command(name)
      command_registry.foobara_lookup_command(name)
    end

    def request_to_command_class(request)
      action = request.action
      full_command_name = request.full_command_name

      if action == "run"
        transformed_command_class = transformed_command_from_name(full_command_name)

        unless transformed_command_class
          # :nocov:
          raise NoCommandFoundError.new(message: "Could not find command registered for #{full_command_name}")
          # :nocov:
        end

        transformed_command_class
      else
        action = case action
                 when "describe_type", "manifest", "describe_command"
                   "describe"
                 when "describe", "ping", "query_git_commit_info", "help"
                   action
                 when "list"
                   "list_commands"
                 else
                   # :nocov:
                   raise InvalidContextError.new(message: "Not sure what to do with #{action}")
                   # :nocov:
                 end

        command_name = Util.classify(action)
        command_class = find_builtin_command_class(command_name)
        full_command_name = command_class.full_command_name

        transformed_command_from_name(full_command_name) || transform_command_class(command_class)
      end
    end

    def request_to_command_inputs(request)
      action = request.action
      full_command_name = request.full_command_name

      case action
      when "run"
        request.inputs
      when "describe"
        manifestable = transformed_command_from_name(full_command_name) || type_from_name(full_command_name)

        unless manifestable
          # :nocov:
          raise NoCommandOrTypeFoundError.new(
            message: "Could not find command or type registered for #{full_command_name}"
          )
          # :nocov:
        end

        request.inputs.merge(manifestable:, request:)
      when "describe_command"
        transformed_command_class = transformed_command_from_name(full_command_name)

        unless transformed_command_class
          # :nocov:
          raise NoCommandFoundError.new(message: "Could not find command registered for #{full_command_name}")
          # :nocov:
        end

        request.inputs.merge(manifestable: transformed_command_class, request:)
      when "describe_type"
        type = type_from_name(full_command_name)

        unless type
          # :nocov:
          raise NoTypeFoundError.new(message: "Could not find type registered for #{full_command_name}")
          # :nocov:
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
        # :nocov:
        raise InvalidContextError.new(message: "Not sure what to do with #{action}")
        # :nocov:
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
      delayed_connections[registerable_name.to_s] = { args:, opts: }
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

    def connect(*args, **opts)
      args, opts = desugarize_connect_args(args, opts)

      registerable = args.first

      if opts.key?(:authenticator)
        authenticator = opts[:authenticator]
        authenticator = self.class.to_authenticator(authenticator)
        opts = opts.merge(authenticator:)
      end

      case registerable
      when Class
        unless registerable < Command
          # :nocov:
          raise "Don't know how to register #{registerable} (#{registerable.class})"
          # :nocov:
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
          # :nocov:
          raise "Don't know how to register #{registerable} (#{registerable.class})"
          # :nocov:
        end
      when Symbol, String
        connect_delayed(*args, **opts)
      else
        # :nocov:
        raise "Don't know how to register #{registerable} (#{registerable.class})"
        # :nocov:
      end
    end

    def desugarize_connect_args(args, opts)
      if self.class.desugarizer
        self.class.desugarizer.process_value!([args, opts])
      else
        # TODO: test this code path by removing all desugarizers in a spec.
        # :nocov:
        [args, opts]
        # :nocov:
      end
    end

    def build_request(...)
      self.class::Request.new(...).tap do |request|
        # TODO: feels like a smell
        request.command_connector = self
      end
    end

    # TODO: maybe introduce a Runner interface?
    def run(...)
      process_delayed_connections

      request = build_request(...)

      run_request(request)
    end

    def run_request(request)
      command_class = determine_command_class(request)
      request.command_class = command_class

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
              # :nocov:
            else
              raise "No command returned from #request_to_command"
              # :nocov:
            end
          end
        end
      ensure
        request.use_transaction do
          if (request.response || request).outcome&.success?
            request.commit_transaction_if_open
          else
            request.rollback_transaction
          end
        end
      end

      build_response(request)
    end

    def run_command(request)
      command = request.command

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

    def type_from_name(name)
      Foobara.foobara_lookup_type(name, mode: Namespace::LookupMode::RELAXED)
    end

    def foobara_manifest
      Namespace.use command_registry do
        foobara_manifest_in_current_namespace
      end
    end

    # TODO: try to break this giant method up
    def foobara_manifest_in_current_namespace
      process_delayed_connections

      to_include = Set.new

      to_include << command_registry.global_organization
      to_include << command_registry.global_domain

      command_registry.foobara_each_command(mode: Namespace::LookupMode::ABSOLUTE_SINGLE_NAMESPACE) do |exposed_command|
        to_include << exposed_command
      end

      included = Set.new

      additional_to_include = Set.new

      h = {
        organization: {},
        domain: {},
        type: {},
        command: {},
        error: {}
      }

      if TypeDeclarations.include_processors?
        h.merge!(
          processor: {},
          processor_class: {}
        )
      end

      TypeDeclarations.with_manifest_context(to_include: additional_to_include, remove_sensitive: true) do
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
                if o.sensitive?
                  # :nocov:
                  raise UnexpectedSensitiveTypeInManifestError,
                        "Unexpected sensitive type in manifest: #{o.scoped_full_path}. " \
                        "Make sure these are not included."
                # :nocov:
                else

                  mode = Namespace::LookupMode::ABSOLUTE_SINGLE_NAMESPACE
                  domain_name = o.foobara_domain.scoped_full_name

                  exposed_domain = command_registry.foobara_lookup_domain(domain_name, mode:)

                  exposed_domain ||= command_registry.build_and_register_exposed_domain(domain_name)

                  # Since we don't know which other domains/orgs creating this domain might have created,
                  # we will just add them all to be included just in case
                  command_registry.foobara_all_domain(mode:).each do |exposed_domain|
                    additional_to_include << exposed_domain
                  end

                  command_registry.foobara_all_organization(mode:).each do |exposed_organization|
                    additional_to_include << exposed_organization
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

          # TODO: do we really need to enter the namespace here for this?
          h[category_symbol][manifest_reference] = Foobara::Namespace.use namespace do
            object.foobara_manifest
          end

          included << object
        end
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
                           fixed_parent = [:domain, domain.reference]

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

      command_registry.foobara_all_command(mode: Namespace::LookupMode::ABSOLUTE_SINGLE_NAMESPACE)
    end

    def all_exposed_command_names
      all_exposed_commands.map(&:full_command_name)
    end

    def all_exposed_type_names
      # TODO: cache this or better yet cache #foobara_manifest
      foobara_manifest[:type].keys.sort.map(&:to_s)
    end
  end
end
