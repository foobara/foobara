require_relative "../attributes"

module Foobara
  module CommandConnectors
    module Desugarizers
      class Attributes < Desugarizer
        class InputsFromYaml < Attributes
          def desugarizer_symbol
            :yaml
          end

          def transformer_method
            :from_yaml
          end

          def opts_key
            :inputs_transformers
          end
        end
      end
    end
  end
end
