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

            def data_schema
              :duck # TODO: fix this when we have a way to specify attributes with unspecified keys
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
