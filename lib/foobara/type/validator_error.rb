require "foobara/type/attribute_error"

module Foobara
  class Type < Value::Processor
    class ValidatorError < Foobara::Type::AttributeError
      class << self
        def symbol
          @symbol ||= Util.module_for(self).name.demodulize.gsub(/Error$/, "").underscore.to_sym
        end

        # are we able to build a context type instead?
        # That's a problem because we wish to express these types via schemas to the outside world.
        # So we would need code to convert a type to a schema for that purpose if we keep type and schema decoupled.
        # A somewhat low-cost way to do that is have a mapping from built-in types to schemas and have external
        # errors define schemas directly. Unnecessary complexity?
        def context_schema
          {
            path: :duck, # TODO: fix this up once there's an array type
            attribute_name: :symbol,
            value: :duck
          }
        end
      end
    end
  end
end
