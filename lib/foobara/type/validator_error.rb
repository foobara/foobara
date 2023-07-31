require "foobara/type/attribute_error"

module Foobara
  class Type
    class ValidatorError < Foobara::Type::AttributeError
      class << self
        def symbol
          @symbol ||= Util.module_for(self).name.demodulize.gsub(/Error$/, "").underscore.to_sym
        end

        def context_schema
          {
            path: :duck, # TODO: fix this up once there's an array type
            attribute_name: :symbol,
            value: :integer,
            max: :integer
          }
        end
      end
    end
  end
end
