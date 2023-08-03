module Foobara
  class Command
    module Concerns
      module Result
        extend ActiveSupport::Concern

        class CouldNotProcessResult < Outcome::UnsuccessfulOutcomeError; end

        def result_type
          @result_type ||= result_schema.to_type
        end

        private

        def process_result_using_result_schema(result)
          return result unless result_schema.present?

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
