module Foobara
  class Model
    class TypeBuilder
      module Processors
        class HaltUnlessSuccess < Foobara::Type::ValueProcessor
          def error_halts_processing?
            true
          end

          # TODO: can we eliminate this processor somehow??
          def process_outcome(outcome, _path)
            outcome
          end
        end
      end
    end
  end
end
