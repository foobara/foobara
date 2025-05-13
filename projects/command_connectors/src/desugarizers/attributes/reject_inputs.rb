require_relative "../attributes"

module Foobara
  module CommandConnectors
    module Desugarizers
      class Attributes < Desugarizer
        class RejectInputs < Attributes
          def desugarizer_symbol
            :reject
          end

          def opts_key
            :inputs_transformers
          end
        end
      end
    end
  end
end
