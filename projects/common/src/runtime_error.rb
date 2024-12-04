Foobara.require_project_file("common", "error")

module Foobara
  # NOTE: annoyingly this will clash with ::RuntimeError if not fully qualified when using
  class RuntimeError < Error
    abstract

    class << self
      def category
        :runtime
      end

      def fatal?
        true
      end
    end

    # TODO: why path instead of runtime path?
    def initialize(message: nil, symbol: nil, context: {}, path: nil)
      args = { message:, symbol:, context:, path: }.compact
      super(**args.merge(category: self.class.category))
    end
  end
end
