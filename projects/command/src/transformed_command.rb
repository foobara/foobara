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

      foobara_delegate :full_command_name, to: :command_class

      def manifest
        # TODO: need to delegate to the transformers when present, not the command!
        command_class.manifest(verbose: true)
      end

      def types_depended_on
        command_class.types_depended_on
      end
    end

    attr_accessor :command, :untransformed_inputs, :transformed_inputs, :outcome, :authenticated_user

    def initialize(untransformed_inputs)
      self.untransformed_inputs = untransformed_inputs || {}

      transform_inputs
      construct_command
    end

    foobara_delegate :full_command_name, to: :command_class
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

            self.outcome = Outcome.error(CommandConnector::NotAllowedError.new(explanation))

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
      # raise # uncomment when debugging. TODO: figure out how to make this not necessary
      if capture_unknown_error
        # TODO: move to superclass?
        self.outcome = Outcome.error(CommandConnector::UnknownError.new(e))
      else
        raise
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
