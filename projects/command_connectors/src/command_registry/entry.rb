module Foobara
  # TODO: move to foobara monorepo if this is generic...
  class CommandRegistry
    class Entry
      attr_accessor :command_class,
                    :inputs_transformer,
                    :result_transformer,
                    :errors_transformer,
                    :allowed_rule

      def initialize(command_class, inputs_transformer:, result_transformer:, errors_transformer:, allowed_rule:)
        self.command_class = command_class
        self.inputs_transformer = inputs_transformer
        self.result_transformer = result_transformer
        self.errors_transformer = errors_transformer
        self.allowed_rule = allowed_rule
      end

      def run_request(request)
        transform_inputs(request)
        construct_command(request)
        apply_allowed_rule(request)

        request.run

        transform_outcome(request)

        request.outcome
      end

      def construct_command(request)
        self.command = command_class.new(transformed_inputs)
      end

      def apply_allowed_rule(request)
        rule = allowed_rule

        if rule
          command = request.command

          command.after_load_records do |command:, **|
            is_allowed = request.instance_eval(&rule)

            unless is_allowed
              command.instance_eval do
                command.not_allowed!
                command.outcome = Outcome.error(NotAllowedError.new(allowed_rule.explanation))
              end
            end
          end
        end
      end

      def transform_inputs(request)
        if inputs_transformer
          request.transformed_inputs = if inputs_transformer.arity > 1
                                         inputs_transformer.call(request.untransformed_inputs, request)
                                       else
                                         inputs_transformer.call(request.untransformed_inputs)
                                       end
        end
      end

      def transform_result(request)
        if result_transformer
          result = if result_transformer.arity > 1
                     result_transformer.call(request.result, request)
                   else
                     result_transformer.call(request.result)
                   end

          request.outcome = Outcome.success(result)
        end
      end

      def transform_errors(request)
        if errors_transformer
          errors = if errors_transformer.arity > 1
                     errors_transformer.call(request.errors, request)
                   else
                     errors_transformer.call(request.errors)
                   end

          request.outcome = Outcome.errors(errors)
        end
      end

      def transform_outcome(request)
        if request.outcome.success?
          transform_result(request)
        else
          transform_errors(request)
        end
      end
    end
  end
end
