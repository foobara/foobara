module Foobara
  module Types
    # TODO: move casting interface to here?
    class Type < Value::Processor
      include Concerns::SupportedProcessorRegistration

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
