module Foobara
  module Callback
    class SingleEventRegistry < AbstractRegistry
      def register_callback(type, &callback_block)
        validate_type!(type)
        validate_block!(type, callback_block)

        callback_blocks = callbacks[type] ||= []

        callback_blocks << callback_block
      end

      def callbacks_for(type)
        validate_type!(type)

        callbacks[type].presence || []
      end
    end
  end
end
