module Foobara
  module Callback
    ALLOWED_CALLBACK_TYPES = %i[before after around error].freeze

    class << self
      def block_class_for(type)
        const_get("#{type.to_s.classify}Block")
      end
    end
  end
end
