module Foobara
  module CommandPatternImplementation
    module Concerns
      module Result
        include Concern

        class CouldNotProcessResult < Outcome::UnsuccessfulOutcomeError;
          attr_accessor :command

          def initialize(command, errors)
            self.command = command

            super(errors, prefix: command.class.full_command_name)
          end
        end

        private

        def process_result_using_result_type(result)
          return result unless result_type

          outcome = result_type.process_value(result)

          if outcome.success?
            outcome.result
          else
            raise CouldNotProcessResult.new(self, outcome.errors)
          end
        end
      end
    end
  end
end
