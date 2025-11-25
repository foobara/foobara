require_relative "../attributes"

module Foobara
  module CommandConnectors
    module Desugarizers
      class Attributes < Desugarizer
        class OnlyResult < Attributes
          def desugarizer_symbol
            :only
          end

          def opts_key
            :result_transformers
          end
        end
      end
    end
  end
end
