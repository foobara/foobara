module Foobara
  class TransformedCommand
    class << self
      attr_accessor :command_class,
                    :capture_unknown_error,
                    :inputs_transformers,
                    :result_transformers,
                    :errors_transformers,
                    :pre_commit_transformers,
                    :serializers,
                    # TODO: Fold these three into some kind of pre-execute validator?
                    :allowed_rule,
                    :requires_authentication,
                    :authenticator

      def subclass(
        command_class,
        inputs_transformers:,
        result_transformers:,
        errors_transformers:,
        pre_commit_transformers:,
        serializers:,
        allowed_rule:,
        requires_authentication:,
        authenticator:,
        capture_unknown_error: true
      )
        Class.new(self).tap do |klass|
          klass.command_class = command_class
          klass.capture_unknown_error = capture_unknown_error
          klass.inputs_transformers = Util.array(inputs_transformers)
          klass.result_transformers = Util.array(result_transformers)
          klass.errors_transformers = Util.array(errors_transformers)
          klass.pre_commit_transformers = Util.array(pre_commit_transformers)
          klass.serializers = Util.array(serializers)
          klass.allowed_rule = allowed_rule
          klass.requires_authentication = requires_authentication
          klass.authenticator = authenticator
        end
      end

      foobara_delegate :full_command_name,
                       :full_command_symbol,
                       :command_name,
                       :description,
                       :domain,
                       :organization,
                       to: :command_class

      def foobara_manifest(to_include:)
        to_include << domain
        to_include << organization

        types = types_depended_on.select(&:registered?).map do |t|
          to_include << t
          t.foobara_manifest_reference
        end.sort

        inputs_transformers = self.inputs_transformers.map { |t| t.foobara_manifest(to_include:) }
        result_transformers = self.result_transformers.map { |t| t.foobara_manifest(to_include:) }
        errors_transformers = self.errors_transformers.map { |t| t.foobara_manifest(to_include:) }
        pre_commit_transformers = self.pre_commit_transformers.map { |t| t.foobara_manifest(to_include:) }
        serializers = self.serializers.map do |s|
          if s.respond_to?(:foobara_manifest)
            to_include << s
            s.foobara_manifest_reference
          else
            { proc: s.to_s }
          end
        end

        command_class.foobara_manifest(to_include:).merge(
          Util.remove_blank(
            types_depended_on: types,
            inputs_type: inputs_type&.reference_or_declaration_data,
            result_type: result_type&.reference_or_declaration_data,
            possible_errors: possible_errors_manifest(to_include:),
            capture_unknown_error:,
            inputs_transformers:,
            result_transformers:,
            errors_transformers:,
            pre_commit_transformers:,
            serializers:,
            requires_authentication:,
            authenticator: authenticator&.manifest
          )
        )
      end

      def foobara_manifest_reference
        command_class.foobara_manifest_reference
      end

      def inputs_type
        input_transformer = inputs_transformers.find do |transformer|
          transformer.is_a?(Class) && transformer < TypeDeclarations::TypedTransformer && transformer.input_type
        end

        if input_transformer
          input_transformer.input_type
        else
          command_class.inputs_type
        end
      end

      def result_type
        output_transformer = result_transformers.reverse.find do |transformer|
          transformer.is_a?(Class) && transformer < TypeDeclarations::TypedTransformer && transformer.output_type
        end

        if output_transformer
          output_transformer.output_type
        else
          command_class.result_type
        end
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

      def possible_errors_manifest(to_include:)
        possible_errors.map do |possible_error|
          [possible_error.key.to_s, possible_error.foobara_manifest(to_include:)]
        end.sort.to_h
      end

      def types_depended_on
        # TODO: memoize this
        # TODO: this should not delegate to command since transformers are in play
        types = command_class.types_depended_on

        type = inputs_type

        if type != command_class.inputs_type
          types |= if type.registered?
                     # TODO: if we ever change from attributes-only inputs type
                     # then this will be handy
                     # :nocov:
                     [type]
                     # :nocov:
                   else
                     type.types_depended_on
                   end
        end

        type = result_type

        if type != command_class.result_type
          types |= if type.registered?
                     # TODO: if we ever change from attributes-only inputs type
                     # then this will be handy
                     # :nocov:
                     [type]
                     # :nocov:
                   else
                     type.types_depended_on
                   end
        end

        types
      end
    end

    attr_accessor :command, :untransformed_inputs, :transformed_inputs, :outcome, :authenticated_user

    def initialize(untransformed_inputs)
      self.untransformed_inputs = untransformed_inputs || {}

      transform_inputs
      construct_command
    end

    foobara_delegate :full_command_name, :description, to: :command_class
    foobara_delegate :command_class,
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
      authenticate if requires_authentication?
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
      self.transformed_inputs = if inputs_transformer
                                  inputs_transformer.process_value!(untransformed_inputs)
                                else
                                  untransformed_inputs
                                end
    end

    def transform_result
      if result_transformer
        self.outcome = Outcome.success(result_transformer.process_value!(result))
      end
    end

    def transform_errors
      if errors_transformer
        self.outcome = Outcome.errors(errors_transformer.process_value!(errors))
      end
    end

    def inputs_transformer
      return nil if inputs_transformers.empty?

      transformers = transformers_to_processors(inputs_transformers)

      if transformers.size == 1
        transformers.first
      else
        Value::Processor::Pipeline.new(processors: transformers)
      end
    end

    def result_transformer
      return nil if result_transformers.empty?

      transformers = transformers_to_processors(result_transformers)

      if transformers.size == 1
        transformers.first
      else
        Value::Processor::Pipeline.new(processors: transformers)
      end
    end

    # TODO: let's get this out of here...
    # we might want to have diferent serializers for different command instances of the same class.
    # but currently serializers is set on the class. Since this class should not be concerned with serialization, we
    # should just try to relocate this to the Request which could delegate to the registry for defaults.
    def serializer
      return nil if serializers.empty?

      transformers = transformers_to_processors(serializers)

      if transformers.size == 1
        transformers.first
      else
        Value::Processor::Pipeline.new(processors: transformers)
      end
    end

    def errors_transformer
      return nil if errors_transformers.empty?

      transformers = transformers_to_processors(errors_transformers)

      if transformers.size == 1
        transformers.first
      else
        Value::Processor::Pipeline.new(processors: transformers)
      end
    end

    # TODO: memoize
    def pre_commit_transformer
      return nil if pre_commit_transformers.empty?

      transformers = transformers_to_processors(pre_commit_transformers)

      if transformers.size == 1
        transformers.first
      else
        Value::Processor::Pipeline.new(processors: transformers)
      end
    end

    def transformers_to_processors(transformers)
      transformers.map do |transformer|
        if transformer.is_a?(Class)
          transformer.new(self)
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

    def construct_command
      self.command = command_class.new(transformed_inputs)
    end

    def authenticate
      command.after_load_records do |command:, **|
        self.authenticated_user = instance_eval(&:authenticator)

        unless authenticated_user
          self.outcome = Outcome.error(CommandConnector::UnauthenticatedError.new)

          command.state_machine.error!
          command.halt!
        end
      end
    end

    def apply_allowed_rule
      rule = allowed_rule

      if rule
        command.after_load_records do |command:, **|
          # NOTE: apparently no way to convert a lambda to a proc but lambda's won't work here...
          # TODO: raise exception here if rule.lambda? is true, if this starts becoming a common error
          is_allowed = instance_eval(&rule)

          unless is_allowed
            explanation = allowed_rule.explanation

            if explanation.is_a?(Proc)
              explanation = instance_eval(&explanation)
            end

            if explanation.nil?
              explanation = allowed_rule.block.source || "No explanation."
            end

            error = CommandConnector::NotAllowedError.new(rule_symbol: rule.symbol, explanation:)
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
        self.outcome = Outcome.error(CommandConnector::UnknownError.new(e))
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
    def serialize_result
      body = if outcome.success?
               outcome.result
             else
               outcome.errors
             end

      if serializer
        serializer.process_value!(body)
      else
        body
      end
    end

    def method_missing(method_name, *, **, &)
      if command.respond_to?(method_name)
        command.send(method_name, *, **, &)
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
