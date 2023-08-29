require "foobara/common/util"

Foobara::Common::Util.require_directory("#{__dir__}/common")

module Foobara
  Foobara::Common.constants.each do |constant_name|
    constant_value = Foobara::Common.const_get(constant_name)
    const_set(constant_name, constant_value)
  end
end
