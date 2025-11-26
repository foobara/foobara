module Foobara
  module Enumerated
    class << self
      def make_module(...)
        Values.new(...).make_module
      end
    end
  end
end
