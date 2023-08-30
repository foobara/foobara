module Foobara
  class Command
    class RuntimeCommandError < Error
      class << self
        def category
          :runtime
        end
      end

      def initialize(message: nil, symbol: nil, context: nil, path: nil)
        args = { message:, symbol:, context:, path: }.compact
        super(**args.merge(category: self.class.category))
      end
    end
  end
end
