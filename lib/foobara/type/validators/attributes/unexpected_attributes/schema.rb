module Foobara
  class Type
    module Validators
      module Attributes
        class UnexpectedAttributes < Value::Validator
          module Schema
            module Desugarizer
              class << self
                def call(rawish_schema)
                  rawish_schema[:unexpected_attributes] = rawish_schema[:schemas].keys

                  Outcome.success(rawish_schema)
                end
              end
            end
          end
        end
      end
    end
  end
end
