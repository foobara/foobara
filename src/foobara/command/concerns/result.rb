module Foobara
  class Command
    module Concerns
      module Result
        extend ActiveSupport::Concern

        class CouldNotProcessResult < Outcome::UnsuccessfulOutcomeError; end

        def result_type
          @result_type ||= Model::TypeBuilder.type_for(result_schema)
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
