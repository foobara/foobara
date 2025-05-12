module Foobara
  class CommandConnector
    class Desugarizer < Value::Transformer
      class << self
        def requires_declaration_data?
          false
        end
      end

      def transform(value)
        desugarize(value)
      end
    end
  end
end
