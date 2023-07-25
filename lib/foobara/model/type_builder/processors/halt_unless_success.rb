module Foobara
  class Model
    class TypeBuilder
      module Processors
        class HaltUnlessSuccess < Foobara::Type::ValueProcessor
          def error_halts_processing?
            true
          end

          def process_outcome(outcome)
            outcome
          end
        end
      end
    end
  end
end
