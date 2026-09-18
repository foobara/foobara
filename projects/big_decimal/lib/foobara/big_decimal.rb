require "foobara/builtin_types"
require "bigdecimal"

module Foobara
  module BigDecimal
    class << self
      def install!
        BuiltinTypes.build_and_register!(:big_decimal, BuiltinTypes[:number])
      end

      def reset_all = install!
    end
  end
end

Foobara.project("big_decimal", project_path: "#{__dir__}/../..")
