module Foobara
  class Command
    module Concerns
      module Result
        extend ActiveSupport::Concern

        class CouldNotProcessResult < Outcome::UnsuccessfulOutcomeError; end

        private

        def process_result_using_result_type(result)
          return result unless result_type.present?

          outcome = result_type.process(result)

          if outcome.success?
            outcome.result
          else
            raise CouldNotProcessResult, outcome.errors
          end
        end
      end
    end
  end
end
