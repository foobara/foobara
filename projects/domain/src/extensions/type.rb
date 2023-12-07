module Foobara
  module Types
    class Type
      def scoped_path
        @scoped_path ||= [type_symbol.to_s]
      end
    end
  end
end
