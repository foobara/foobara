module Foobara
  class Model
    class TypeBuilder
      module Processors
        class HaltUnlessSuccess < Foobara::Type::ValueProcessor
          def error_halts_processing?
            true
          end

          # can we do this some other way??
          def process_outcome(outcome)
            outcome
          end
        end
      end
    end
  end
end
