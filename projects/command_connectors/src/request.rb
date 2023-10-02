module Foobara
  module CommandConnector
    class Request
      attr_accessor :registry_entry, :command, :transformed_inputs, :outcome

      def initialize(registry_entry)
        self.registry_entry = registry_entry
      end

      def full_command_name
        raise "subclass responsibility"
      end

      def untransformed_inputs
        raise "subclass responsibility"
      end

      foobara_delegate :command_class,
                       :inputs_transformer,
                       :result_transformer,
                       :errors_transformer,
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
        self.transformed_inputs = if inputs_transformer
                                    if inputs_transformer.arity > 1
                                      inputs_transformer.call(untransformed_inputs, self)
                                    else
                                      inputs_transformer.call(untransformed_inputs)
                                    end
                                  else
                                    untransformed_inputs
                                  end
      end

      def construct_command
        self.command = command_class.new(transformed_inputs)
      end

      def apply_allowed_rule
        rule = allowed_rule

        if rule
          command.after_load_records do |command:, **|
            is_allowed = instance_eval(&rule)

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

      def transform_result
        if result_transformer
          self.result = if result_transformer.arity > 1
                          result_transformer.call(result, self)
                        else
                          result_transformer.call(result)
                        end
        end

        self.outcome = Outcome.success(result)
      end

      def transform_errors
        if errors_transformer
          errors = if errors_transformer.arity > 1
                     errors_transformer.call(self.errors, self)
                   else
                     errors_transformer.call(self.errors)
                   end

          self.outcome = Outcome.errors(errors)
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
