module Foobara
  module CommandConnector
    class Request
      attr_accessor :registry_entry, :command, :transformed_inputs, :outcome

      def initialize(registry_entry)
        self.registry_entry = registry_entry
      end

      def full_command_name
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def untransformed_inputs
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      foobara_delegate :command_class,
                       :inputs_transformers,
                       :result_transformers,
                       :errors_transformers,
                       :allowed_rule,
                       to: :registry_entry

      def run
        transform_inputs
        construct_command
        apply_allowed_rule
        run_command
        transform_outcome

        outcome
      end

      def transform_inputs
        self.transformed_inputs = inputs_transformer.process_value!(untransformed_inputs)
      end

      def transform_result
        self.outcome = Outcome.success(result_transformer.process_value!(result))
      end

      def transform_errors
        self.outcome = Outcome.errors(errors_transformer.process_value!(errors))
      end

      def inputs_transformer
        processors = transformers_to_processors(inputs_transformers)
        Value::Processor::Pipeline.new(processors:)
      end

      def result_transformer
        processors = transformers_to_processors(result_transformers)
        Value::Processor::Pipeline.new(processors:)
      end

      def errors_transformer
        processors = transformers_to_processors(errors_transformers)
        Value::Processor::Pipeline.new(processors:)
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

      def apply_allowed_rule
        rule = allowed_rule

        if rule
          command.after_load_records do |command:, **|
            # use validation errors instead???
            is_allowed = instance_eval { rule.call }

            unless is_allowed
              command.not_allowed!
              command.outcome = Outcome.error(NotAllowedError.new(allowed_rule.explanation))
            end
          end
        end
      end

      def run_command
        self.outcome = command.run
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

      def method_missing(method_name, *, **, &)
        if command.respond_to?(method_name)
          command.send(method_name, *, **, &)
        else
          super
        end
      end

      def respond_to_missing?(method_name, private = false)
        command.respond_to?(method_name, private) || super
      end
    end
  end
end
