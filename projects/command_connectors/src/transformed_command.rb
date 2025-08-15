module Foobara
  # TODO: feels so strange that this doesn't inherit from command
  class TransformedCommand
    class << self
      # TODO: handle errors_transformers!
      attr_writer :result_transformers, :inputs_transformers
      attr_accessor :command_class,
                    :command_name,
                    :full_command_name,
                    :capture_unknown_error,
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
                    :authenticator,
                    :subclassed_in_namespace,
                    :suffix

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
          klass.subclassed_in_namespace = scoped_namespace
          klass.suffix = suffix
        end
      end

      foobara_delegate :description,
                       :domain,
                       :organization,
                       to: :command_class

      def result_transformers
        return @result_transformers if @considered_sensitive_value_remover

        @considered_sensitive_value_remover = true

        result_type = command_class.result_type

        result_transformers.reverse.each do |transformer|
          if transformer.is_a?(TypeDeclarations::TypedTransformer) ||
             (transformer.is_a?(Class) && transformer < TypeDeclarations::TypedTransformer)
            new_type = transformer.to_type
            if new_type
              result_type = new_type
              break
            end
          end
        end

        if result_type&.has_sensitive_types?
          remover_class = Foobara::TypeDeclarations.sensitive_value_remover_class_for_type(result_type)

          remover = Namespace.use subclassed_in_namespace do
            path = if result_type.scoped_path_set?
                     result_type.scoped_full_path
                   else
                     [*command_class.scoped_path, *suffix, "Result"]
                   end

            remover_class.new(from: result_type).tap do |r|
              r.scoped_path = ["SensitiveValueRemover", *path]
            end
          end

          @result_transformers = [*@result_transformers, remover]
        end

        @result_transformers
      end

      def inputs_transformers
        return @inputs_transformers if @considered_inputs_sensitive_value_remover

        @considered_inputs_sensitive_value_remover = true

        inputs_type = command_class.inputs_type

        @inputs_transformers = transformers_to_processors(@inputs_transformers, inputs_type, direction: :to)
        @inputs_transformers = @inputs_transformers.reverse

        # TODO: this block looks pointless...
        @inputs_transformers.each do |transformer|
          if transformer.is_a?(TypeDeclarations::TypedTransformer)
            new_type = transformer.from_type
            if new_type
              inputs_type = new_type
              break
            end
          end
        end

        @inputs_transformers
      end

      def inputs_type_for_manifest
        return @inputs_type_for_manifest if defined?(@inputs_type_for_manifest)

        @inputs_type_for_manifest = if inputs_type&.has_sensitive_types?
                                      remover_class = Foobara::TypeDeclarations.sensitive_value_remover_class_for_type(
                                        inputs_type
                                      )

                                      Namespace.use subclassed_in_namespace do
                                        remover_class.new(to: inputs_type).from_type
                                      end
                                    else
                                      inputs_type
                                    end
      end

      def inputs_type_from_transformers
        return @inputs_type_from_transformers if defined?(@inputs_type_from_transformers)

        @inputs_type_from_transformers = if inputs_transformer
                                           if inputs_transformer.is_a?(Value::Processor::Pipeline)
                                             inputs_transformer.processors.each do |transformer|
                                               if transformer.is_a?(TypeDeclarations::TypedTransformer)
                                                 from_type = transformer.from_type
                                                 if from_type
                                                   @inputs_type_from_transformers = from_type
                                                   return from_type
                                                 end
                                               end
                                             end

                                             command_class.inputs_type
                                           else
                                             if inputs_transformer.is_a?(TypeDeclarations::TypedTransformer)
                                               inputs_transformer.from_type
                                             end || command_class.inputs_type
                                           end
                                         else
                                           command_class.inputs_type
                                         end
      end

      def result_type_from_transformers
        result_transformers.reverse.each do |transformer|
          if transformer.is_a?(TypeDeclarations::TypedTransformer) ||
             (transformer.is_a?(Class) && transformer < TypeDeclarations::TypedTransformer)
            new_type = transformer.to_type
            return new_type if new_type
          end
        end

        command_class.result_type
      end

      def result_type
        return @result_type if defined?(@result_type)

        mutated_result_type = result_type_from_transformers

        mutators = if response_mutators.size == 1
                     [response_mutator]
                   else
                     response_mutator&.processors&.reverse
                   end

        mutators&.each do |mutator|
          mutated_result_type = mutator.result_type_from(mutated_result_type)
        end

        @result_type = mutated_result_type
      end

      def inputs_type
        return @inputs_type if defined?(@inputs_type)

        mutated_inputs_type = inputs_type_from_transformers

        mutators = if request_mutators.size == 1
                     [request_mutator]
                   else
                     request_mutator&.processors
                   end

        mutators&.each do |mutator|
          mutated_inputs_type = mutator.inputs_type_from(mutated_inputs_type)
        end

        @inputs_type = mutated_inputs_type
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
          inputs_type&.types_depended_on || []
        end
      end

      def result_types_depended_on
        type_proc = -> { result_type&.types_depended_on || [] }

        if TypeDeclarations.manifest_context_set?(:remove_sensitive)
          type_proc.call
        else
          TypeDeclarations.with_manifest_context(remove_sensitive: true, &type_proc)
        end
      end

      def types_depended_on
        types = Set.new

        # TODO: memoize this
        # TODO: this should not delegate to command since transformers are in play

        types_proc = proc do
          type = inputs_type_for_manifest

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

        response_mutators = mutators_to_manifest_symbols(self.response_mutators, to_include:)
        request_mutators = mutators_to_manifest_symbols(self.request_mutators, to_include:)

        authenticator_details = if authenticator
                                  {
                                    symbol: authenticator.symbol,
                                    explanation: authenticator.explanation
                                  }
                                end

        inputs_types_depended_on = TypeDeclarations.with_manifest_context(remove_sensitive: false) do
          self.inputs_types_depended_on.map(&:foobara_manifest_reference).sort
        end

        result_types_depended_on = self.result_types_depended_on.map(&:foobara_manifest_reference)
        result_types_depended_on = result_types_depended_on.sort

        bit_bucket = Set.new
        manifest = TypeDeclarations.with_manifest_context(to_include: bit_bucket) do
          command_class.foobara_manifest
        end

        # TODO: handle errors_types_depended_on!
        manifest.merge(
          Util.remove_blank(
            inputs_types_depended_on:,
            result_types_depended_on:,
            types_depended_on: types,
            inputs_type: inputs_type_for_manifest&.reference_or_declaration_data,
            result_type: result_type&.reference_or_declaration_data,
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
            authenticator: authenticator_details
          )
        )
      end

      def mutators_to_manifest_symbols(mutators, to_include:)
        return nil if mutators.nil? || mutators.empty?

        mutators.map do |mutator|
          if mutator.scoped_path_set?
            to_include << mutator
            mutator.foobara_manifest_reference
          elsif mutator.is_a?(Value::Mutator)
            klass = mutator.class

            if klass.scoped_path_set?
              to_include << klass
              klass.foobara_manifest_reference
              # TODO: Delete this nocov block
              # TODO: make anonymous scoped path's have better names instead of random hexadecimal
              # :nocov:
            elsif mutator.symbol
              mutator.symbol
            else

              to_include << klass if klass.scoped_path_set?

              name = klass.name

              while name.nil?
                klass = klass.superclass
                name = klass.name
              end

              "Anonymous#{Util.non_full_name(name)}"
              # :nocov:
            end
          end
        end
      end

      def inputs_transformer
        return @inputs_transformer if defined?(@inputs_transformer)

        transformers = inputs_transformers

        if transformers.empty?
          @inputs_transformer = nil
          return
        end

        @inputs_transformer = if transformers.size == 1
                                transformers.first
                              else
                                Value::Processor::Pipeline.new(processors: transformers)
                              end
      end

      def response_mutator
        return @response_mutator if defined?(@response_mutator)

        # A hack: this will give the SensitiveValueRemover a chance to be injected
        result_transformers

        if response_mutators.empty?
          @response_mutator = nil
          return
        end

        @response_mutator = begin
          transformers = transformers_to_processors(response_mutators, result_type_from_transformers, direction: :from)

          if transformers.size == 1
            transformers.first
          else
            Value::Processor::Pipeline.new(processors: transformers)
          end
        end
      end

      def request_mutator
        return @request_mutator if defined?(@request_mutator)

        # HACK: to give SensitiveValueRemover a chance to be injected
        inputs_transformer

        if request_mutators.empty?
          @request_mutator = nil
          return
        end

        @request_mutator = begin
          transformers = transformers_to_processors(request_mutators, inputs_type_from_transformers, direction: :to)

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
              # TODO: perhaps pass in the command connector as the parent declaration data?
              transformer.new_with_agnostic_args(declaration_data:)
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

    attr_accessor :command, :untransformed_inputs, :transformed_inputs, :outcome, :request

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
                     :allowed_rule,
                     :authenticator,
                     to: :class

    def run
      apply_allowed_rule
      apply_pre_commit_transformers
      set_inputs
      run_command
      # this gives us primary keys
      flush_transactions
      transform_outcome

      outcome
    end

    def authenticated_user
      request.authenticated_user
    end

    def authenticated_credential
      request.authenticated_credential
    end

    def transform_inputs
      self.transformed_inputs = if self.class.inputs_transformer
                                  outcome = self.class.inputs_transformer.process_value(untransformed_inputs)

                                  if outcome.success?
                                    outcome.result
                                  else
                                    self.outcome = outcome
                                    untransformed_inputs
                                  end
                                else
                                  untransformed_inputs
                                end
    end

    def inputs
      return @inputs if defined?(@inputs)

      @inputs = if inputs_type
                  outcome = inputs_type.process_value(untransformed_inputs)

                  if outcome.success?
                    outcome.result
                  else
                    untransformed_inputs
                  end
                else
                  {}
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
      if errors_transformer&.applicable?(errors)
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
          if pre_commit_transformer.applicable?(self)
            pre_commit_transformer.process_value!(self)
          end
        end
      end
    end

    def set_inputs
      if self.class.inputs_type
        command.after_cast_and_validate_inputs do |**|
          inputs
        end
      end
    end

    def run_command
      outcome = command.run
      self.outcome = outcome if outcome
    rescue => e
      if capture_unknown_error
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

    def flush_transactions
      request.opened_transactions&.reverse&.each(&:flush!)
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

    def raw_inputs
      untransformed_inputs
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
