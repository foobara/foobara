module Foobara
  module TypeDeclarations
    class TypeDeclarationError < Foobara::Value::DataError
      def fatal?
        true
      end
    end
  end
end
