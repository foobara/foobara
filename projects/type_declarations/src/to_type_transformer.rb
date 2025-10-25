require_relative "transformer"

module Foobara
  module TypeDeclarations
    class ToTypeTransformer < Transformer
      def always_applicable?
        true
      end
    end
  end
end
