module Foobara
  module Type
    # TODO: rename
    # TODO: move casting interface to here?
    class TypeClass < Value::Processor
      class << self
        attr_accessor :root_type
      end

      attr_accessor :base_type

      def initialize(
        *args,
        base_type: self.class.root_type,
        **opts
      )
        self.base_type = base_type

        super(*args, **opts)
      end

      def possible_errors
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end
    end
  end
end
