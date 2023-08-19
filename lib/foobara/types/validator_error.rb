require "foobara/value/attribute_error"

module Foobara
  module Types
    class ValidatorError < Foobara::Value::AttributeError
      class << self
        # are we able to build a context type instead?
        # That's a problem because we wish to express these types via schemas to the outside world.
        # So we would need code to convert a type to a schema for that purpose if we keep type and schema decoupled.
        # A somewhat low-cost way to do that is have a mapping from built-in types to schemas and have external
        # errors define schemas directly. Unnecessary complexity?
        def context_schema
          {
            value: :duck
          }
        end
      end
    end
  end
end
