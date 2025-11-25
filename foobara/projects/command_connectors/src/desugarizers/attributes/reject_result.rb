require_relative "../attributes"

module Foobara
  module CommandConnectors
    module Desugarizers
      class Attributes < Desugarizer
        class RejectResult < Attributes
          def desugarizer_symbol
            :reject
          end

          def opts_key
            :result_transformers
          end
        end
      end
    end
  end
end
