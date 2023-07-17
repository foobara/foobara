module Foobara
  class Command
    class InputError < Error
      attr_accessor :input

      def initialize(input:, **data)
        super(**data)

        self.input = input
      end
    end
  end
end