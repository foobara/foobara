Foobara.require_file("common", "error")

module Foobara
  # NOTE: annoyingly this will clash with ::RuntimeError if not fully qualified when using
  class RuntimeError < Error
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
