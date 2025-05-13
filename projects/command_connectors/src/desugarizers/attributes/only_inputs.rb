require_relative "../attributes"

module Foobara
  module CommandConnectors
    module Desugarizers
      class Attributes < Desugarizer
        class OnlyInputs < Attributes
          def desugarizer_symbol
            :only
          end

          def opts_key
            :inputs_transformers
          end
        end
      end
    end
  end
end
