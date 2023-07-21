module Foobara
  class Model
    class Schema
      module Concerns
        module PrimitiveSchema
          extend ActiveSupport::Concern

          class_methods do
            def can_handle?(sugary_schema)
              sugary_schema == type
            end
          end

          private

          def desugarize
            if raw_schema == type
              { type: }
            else
              raw_schema
            end
          end
        end
      end
    end
  end
end
