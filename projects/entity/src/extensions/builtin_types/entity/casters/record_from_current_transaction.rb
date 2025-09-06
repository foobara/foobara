require_relative "primary_key"

module Foobara
  module BuiltinTypes
    module Entity
      module Casters
        class RecordFromCurrentTransaction < PrimaryKey
          def applicable?(value)
            if value.is_a?(entity_class)
              tx = entity_class.entity_base.current_transaction
              !tx&.currently_open? || tx.tracking?(value)
            end
          end

          def transform(record)
            record
          end
        end
      end
    end
  end
end
