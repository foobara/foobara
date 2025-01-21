require "date"
require "time"
require "bigdecimal"

module Foobara
  module ModelAttributeHelpers
    class << self
      def install!
        Model.include Concerns::AttributeHelpers
        Model.include Concerns::AttributeHelperAliases
        Entity.include Concerns::AttributeHelpers
        Entity.include Concerns::AttributeHelperAliases
      end
    end
  end
end
