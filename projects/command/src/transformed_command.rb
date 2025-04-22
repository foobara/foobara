module Foobara
  # TODO: feels so strange that this doesn't inherit from command
  # TODO: move this to command connectors project
  class TransformedCommand
    class << self
      attr_accessor :command_class,
                    :command_name,
                    :full_command_name,
                    :capture_unknown_error,
                    :inputs_transformers,
                    :result_transformers,
                    :errors_transformers,
                    :pre_commit_transformers,
                    # TODO: get at least these serializers out of here...
                    :serializers,
                    # TODO: probably should also get these mutators out of here. But where should they live?
                    # On exposed command? On the command registry? On the command connector?
                    # This is the easiest place to implement them but feels awkward.
                    :response_mutators,
                    :request_mutators,
                    :allowed_rule,
                    :requires_authentication,
                    :authenticator

      def subclass(
        command_class,
        scoped_namespace:,
        full_command_name:,
        command_name:,
        inputs_transformers:,
        result_transformers:,
        errors_transformers:,
        pre_commit_transformers:,
        serializers:,
        response_mutators:,
        request_mutators:,
        allowed_rule:,
        requires_authentication:,
        authenticator:,
        suffix: nil,
        capture_unknown_error: false
      )
        result_type = command_class.result_type

        if result_type&.has_sensitive_types?
          remover_class = Foobara::TypeDeclarations.sensitive_value_remover_class_for_type(result_type)

          remover = Namespace.use scoped_namespace do
            transformed_result_type = result_type_from_transformers(result_type, result_transformers)
            remover_class.new(from: transformed_result_type).tap do |r|
              r.scoped_path = ["SensitiveValueRemover", *transformed_result_type.scoped_full_path]
            end
          end

          result_transformers = [*result_transformers, remover]
        end

        Class.new(self).tap do |klass|
          klass.command_class = command_class
          klass.command_name = command_name
          klass.full_command_name = full_command_name
          klass.capture_unknown_error = capture_unknown_error
          klass.inputs_transformers = Util.array(inputs_transformers)
          klass.result_transformers = Util.array(result_transformers)
          klass.errors_transformers = Util.array(errors_transformers)
          klass.pre_commit_transformers = Util.array(pre_commit_transformers)
          klass.serializers = Util.array(serializers)
          klass.response_mutators = Util.array(response_mutators)
          klass.request_mutators = Util.array(request_mutators)
          klass.allowed_rule = allowed_rule
          klass.requires_authentication = requires_authentication
          klass.authenticator = authenticator
        end
      end

      foobara_delegate :description,
                       :domain,
                       :organization,
                       to: :command_class

      def inputs_type
        return @inputs_type if defined?(@inputs_type)

        @inputs_type = if inputs_transformer
                         if inputs_transformer.is_a?(Value::Processor::Pipeline)
                           inputs_transformer.processors.each do |transformer|
                             if transformer.is_a?(TypeDeclarations::TypedTransformer)
                               from_type = transformer.from_type
                               if from_type
                                 @inputs_type = from_type
                                 return from_type
                               end
                             end
                           end

                           command_class.inputs_type
                         else
                           inputs_transformer.from_type || command_class.inputs_type
                         end
                       else
                         command_class.inputs_type
                       end
      end

      def result_type_from_transformers(result_type, transformers)
        transformers.reverse.each do |transformer|
          if transformer.is_a?(Class) && transformer < TypeDeclarations::TypedTransformer
            new_type = transformer.to_type
            return new_type if new_type
          end
        end

        result_type
      end

      def result_type
        result_type_from_transformers(command_class.result_type, result_transformers)
      end

      def result_type_for_manifest
        return @result_type_for_manifest if defined?(@result_type_for_manifest)

        mutated_result_type = result_type

        response_mutators&.reverse&.each do |mutator|
          mutated_result_type = mutator.instance.result_type_from(mutated_result_type)
        end

        @result_type_for_manifest = mutated_result_type
      end

      def inputs_type_for_manifest
        return @inputs_type_for_manifest if defined?(@inputs_type_for_manifest)

        mutated_inputs_type = inputs_type

        request_mutators&.each do |mutator|
          mutated_inputs_type = mutator.instance.inputs_type_from(mutated_inputs_type)
        end

        @inputs_type_for_manifest = mutated_inputs_type
      end

      def error_context_type_map
        @error_context_type_map ||= begin
          set = {}

          command_class.possible_errors.each do |possible_error|
            # For now, we get the input errors off the transformed inputs_type.
            # This way if an inputs transformer changes the path of an input, we don't wind up with the old path
            # in the errors.
            if possible_error.error_class < Foobara::RuntimeError
              set[possible_error.key.to_s] = possible_error
            end
          end

          command_class.manually_added_possible_input_errors.each do |possible_error|
            set[possible_error.key.to_s] = possible_error
          end

          inputs_type&.possible_errors&.each do |possible_error|
            set[possible_error.key.to_s] = possible_error
          end

          errors_transformers.each do |transformer|
            set = transformer.transform_error_context_type_map(self, set)
          end

          set
        end
      end

      def possible_errors
        @possible_errors ||= error_context_type_map.values
      end

      def possible_errors_manifest
        errors_proc = -> do
          possible_errors.map do |possible_error|
            [possible_error.key.to_s, possible_error.foobara_manifest]
          end.sort.to_h
        end

        if TypeDeclarations.manifest_context_set?(:remove_sensitive)
          errors_proc.call
        else
          TypeDeclarations.with_manifest_context(remove_sensitive: true, &errors_proc)
        end
      end

      def inputs_types_depended_on
        TypeDeclarations.with_manifest_context(remove_sensitive: false) do
          inputs_type_for_manifest&.types_depended_on || []
        end
      end

      def result_types_depended_on
        type_proc = -> { result_type_for_manifest&.types_depended_on || [] }

        if TypeDeclarations.manifest_context_set?(:remove_sensitive)
          type_proc.call
        else
          TypeDeclarations.with_manifest_context(remove_sensitive: true, &type_proc)
        end
      end

      def types_depended_on
        # Seems to be not necessary?
        # types = command_class.types_depended_on

        types = Set.new

        # TODO: memoize this
        # TODO: this should not delegate to command since transformers are in play

        type = inputs_type

        if type
          if type.registered?
            # TODO: if we ever change from attributes-only inputs type
            # then this will be handy
            # :nocov:
            types |= [type]
            # :nocov:
          end

          types |= type.types_depended_on
        end

        types_proc = proc do
          type = result_type

          if type
            if type.registered?
              # TODO: if we ever change from attributes-only inputs type
              # then this will be handy
              # :nocov:
              types |= [type]
              # :nocov:
            end

            types |= type.types_depended_on
          end

          possible_errors.each do |possible_error|
            error_class = possible_error.error_class
            types |= error_class.types_depended_on
          end

          types
        end

        if TypeDeclarations.manifest_context_set?(:remove_sensitive)
          types_proc.call
        else
          TypeDeclarations.with_manifest_context(remove_sensitive: true, &types_proc)
        end
      end

      def foobara_manifest
        to_include = TypeDeclarations.foobara_manifest_context_to_include

        types = types_depended_on.select(&:registered?).map do |t|
          if to_include
            to_include << t
          end
          t.foobara_manifest_reference
        end.sort

        inputs_transformers = TypeDeclarations.with_manifest_context(remove_sensitive: false) do
          self.inputs_transformers.map(&:foobara_manifest)
        end
        result_transformers = self.result_transformers.map(&:foobara_manifest)
        errors_transformers = self.errors_transformers.map(&:foobara_manifest)
        pre_commit_transformers = self.pre_commit_transformers.map(&:foobara_manifest)
        serializers = self.serializers.map do |s|
          if s.respond_to?(:foobara_manifest)
            if to_include
              to_include << s
            end
            s.foobara_manifest_reference
          else
            { proc: s.to_s }
          end
        end

        response_mutators = self.response_mutators.map(&:foobara_manifest)
        request_mutators = TypeDeclarations.with_manifest_context(remove_sensitive: false) do
          self.request_mutators.map(&:foobara_manifest)
        end

        authenticator_manifest = if authenticator
                                   if authenticator.respond_to?(:foobara_manifest)
                                     # TODO: test this path
                                     # :nocov:
                                     authenticator.foobara_manifest
                                     # :nocov:
                                   else
                                     true
                                   end
                                 end

        inputs_types_depended_on =  TypeDeclarations.with_manifest_context(remove_sensitive: false) do
          self.inputs_types_depended_on.map(&:foobara_manifest_reference).sort
        end

        result_types_depended_on = self.result_types_depended_on.map(&:foobara_manifest_reference)
        result_types_depended_on = result_types_depended_on.sort

        # TODO: Do NOT defer to command_class.foobara_manifest because it might process types that
        # might not have an exposed command and might not need one due to transformers/mutators/remove_sensitive flag
        command_class.foobara_manifest.merge(
          Util.remove_blank(
            inputs_types_depended_on:,
            result_types_depended_on:,
            types_depended_on: types,
            inputs_type: TypeDeclarations.with_manifest_context(remove_sensitive: false) do
              inputs_type_for_manifest&.reference_or_declaration_data
            end,
            result_type: result_type_for_manifest&.reference_or_declaration_data,
            possible_errors: possible_errors_manifest,
            capture_unknown_error:,
            inputs_transformers:,
            result_transformers:,
            errors_transformers:,
            pre_commit_transformers:,
            serializers:,
            response_mutators:,
            request_mutators:,
            requires_authentication:,
            authenticator: authenticator_manifest
          )
        )
      end

      def inputs_transformer
        return @inputs_transformer if defined?(@inputs_transformer)

        if inputs_transformers.empty?
          @inputs_transformer = nil
          return
        end

        @inputs_transformer = begin
          transformers = transformers_to_processors(inputs_transformers,
                                                    command_class.inputs_type, direction: :to)

          if transformers.size == 1
            transformers.first
          else
            Value::Processor::Pipeline.new(processors: transformers)
          end
        end
      end

      def response_mutator
        return @response_mutator if defined?(@response_mutator)

        if response_mutators.empty?
          @response_mutator = nil
          return
        end

        @response_mutator = begin
          transformers = transformers_to_processors(response_mutators, result_type, direction: :from)

          if transformers.size == 1
            transformers.first
          else
            Value::Processor::Pipeline.new(processors: transformers)
          end
        end
      end

      def request_mutator
        return @request_mutator if defined?(@request_mutator)

        if request_mutators.empty?
          @request_mutator = nil
          return
        end

        @request_mutator = begin
          transformers = transformers_to_processors(request_mutators, result_type, direction: :to)

          if transformers.size == 1
            transformers.first
          else
            Value::Processor::Pipeline.new(processors: transformers)
          end
        end
      end

      def mutate_request(request)
        request_mutator&.process_value!(request)
      end

      def result_transformer
        return @result_transformer if defined?(@result_transformer)

        if result_transformers.empty?
          @result_transformer = nil
          return
        end

        @result_transformer = begin
          transformers = transformers_to_processors(result_transformers, command_class.result_type, direction: :from)

          if transformers.size == 1
            transformers.first
          else
            Value::Processor::Pipeline.new(processors: transformers)
          end
        end
      end

      # TODO: this is pretty messy with smells.
      def transformers_to_processors(transformers, target_type, direction: :from, declaration_data: self)
        transformers.map do |transformer|
          if transformer.is_a?(Class)
            if transformer < TypeDeclarations::TypedTransformer
              transformer.new(direction => target_type).tap do |tx|
                new_type = direction == :from ? tx.to_type : tx.from_type
                target_type = new_type if new_type
              end
            else
              transformer.new(declaration_data)
            end
          elsif transformer.is_a?(Value::Processor)
            transformer
          elsif transformer.respond_to?(:call)
            Value::Transformer.create(transform: transformer)
          else
            # :nocov:
            raise "Not sure how to apply #{inputs_transformer}"
            # :nocov:
          end
        end
      end
    end

    attr_accessor :command, :untransformed_inputs, :transformed_inputs, :outcome, :authenticated_user

    def initialize(untransformed_inputs = {})
      self.untransformed_inputs = untransformed_inputs || {}

      transform_inputs
      construct_command
    end

    foobara_delegate :description, to: :command_class
    foobara_delegate :full_command_name,
                     :command_name,
                     :command_class,
                     :capture_unknown_error,
                     :inputs_transformers,
                     :result_transformers,
                     :errors_transformers,
                     :pre_commit_transformers,
                     :serializers,
                     :requires_authentication,
                     :allowed_rule,
                     :authenticator,
                     to: :class

    def run
      apply_allowed_rule
      apply_pre_commit_transformers
      run_command
      # TODO: do this within the transaction!!!
      transform_outcome

      outcome
    end

    def requires_authentication?
      !!requires_authentication
    end

    def transform_inputs
      self.transformed_inputs = if self.class.inputs_transformer
                                  self.class.inputs_transformer.process_value!(untransformed_inputs)
                                else
                                  untransformed_inputs
                                end
    end

    def transform_result
      if self.class.result_transformer
        self.outcome = Outcome.success(self.class.result_transformer.process_value!(result))
      end
    end

    def mutate_response(response)
      self.class.response_mutator&.process_value!(response)
    end

    def transform_errors
      if errors_transformer
        self.outcome = Outcome.errors(errors_transformer.process_value!(errors))
      end
    end

    # TODO: let's get this out of here...
    # we might want to have different serializers for different command instances of the same class.
    # but currently serializers is set on the class. Since this class should not be concerned with serialization, we
    # should just try to relocate this to the Request which could delegate to the registry for defaults.
    def serializer
      return nil if serializers.empty?

      transformers = self.class.transformers_to_processors(serializers, nil, declaration_data: self)

      if transformers.size == 1
        transformers.first
      else
        Value::Processor::Pipeline.new(processors: transformers)
      end
    end

    def errors_transformer
      return nil if errors_transformers.empty?

      transformers = self.class.transformers_to_processors(errors_transformers, nil, direction: :from,
                                                                                     declaration_data: self)

      if transformers.size == 1
        transformers.first
      else
        Value::Processor::Pipeline.new(processors: transformers)
      end
    end

    # TODO: memoize
    def pre_commit_transformer
      return nil if pre_commit_transformers.empty?

      transformers = self.class.transformers_to_processors(
        pre_commit_transformers,
        nil,
        declaration_data: self
      )

      if transformers.size == 1
        transformers.first
      else
        Value::Processor::Pipeline.new(processors: transformers)
      end
    end

    def construct_command
      self.command = command_class.new(transformed_inputs)
    end

    def apply_allowed_rule
      rule = allowed_rule

      if rule
        command.after_load_records do |command:, **|
          is_allowed = instance_exec(&rule)

          unless is_allowed
            explanation = allowed_rule.explanation

            if explanation.is_a?(Proc)
              explanation = instance_eval(&explanation)
            end

            if explanation.nil?
              source = if allowed_rule.block.respond_to?("source") && defined?(MethodSource)
                         begin
                           # This only works when pry is loaded
                           allowed_rule.block.source
                         rescue MethodSource::SourceNotFoundError
                           # This path is hit if the way the source code is extracted
                           # doesn't result in valid Ruby, for example, as part of a hash such as:
                           # allowed_rule: -> () { whatever?(something) },
                         end
                       end

              source ||= allowed_rule.block.source_location.join(":")
              explanation = source || "No explanation."
            end

            error = CommandConnector::NotAllowedError.for(rule_symbol: rule.symbol, explanation:)
            self.outcome = Outcome.error(error)

            command.state_machine.error!
            command.halt!
          end
        end
      end
    end

    def apply_pre_commit_transformers
      if pre_commit_transformer
        command.before_commit_transaction do |**|
          pre_commit_transformer.process_value!(self)
        end
      end
    end

    def run_command
      outcome = command.run
      self.outcome = outcome if outcome
    rescue => e
      if capture_unknown_error
        # TODO: move to superclass?
        self.outcome = Outcome.error(CommandConnector::UnknownError.for(e))
      else
        # :nocov:
        raise
        # :nocov:
      end
    end

    def result
      outcome.result
    end

    def errors
      outcome.errors
    end

    def transform_outcome
      if outcome.success?
        # can we do this while still in the transaction of the command???
        transform_result
      else
        transform_errors
      end
    end

    # TODO: kill this
    def serialize_result(body)
      if serializer
        serializer.process_value!(body)
      else
        body
      end
    end

    def method_missing(method_name, ...)
      if command.respond_to?(method_name)
        command.send(method_name, ...)
      else
        # :nocov:
        super
        # :nocov:
      end
    end

    def respond_to_missing?(method_name, private = false)
      command.respond_to?(method_name, private) || super
    end
  end
end
