require "foobara/type/value_transformer"

module Foobara
  class Type
    module Transformers
      module Attributes
        class AddDefaults < Foobara::Type::ValueTransformer
          class << self
            # TODO: have convention of grabbing this from the class name instead
            def symbol
              :defaults
            end
          end

          attr_accessor :defaults

          def initialize(defaults)
            super()
            self.defaults = defaults
          end

          def transform(attributes_hash)
            defaults.merge(attributes_hash)
          end
        end
      end
    end
  end
end
