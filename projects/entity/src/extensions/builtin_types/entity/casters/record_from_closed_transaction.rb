require_relative "primary_key"

module Foobara
  module BuiltinTypes
    module Entity
      module Casters
        class RecordFromClosedTransaction < PrimaryKey
          def applicable?(value)
            if value.is_a?(entity_class) && value.persisted?
              tx = value.class.entity_base.current_transaction

              if tx&.currently_open?
                # TODO: might be safer/more performant to store the transaction on the record?
                !value.class.entity_base.current_transaction.tracking?(value)
              end
            end
          end

          def transform(record)
            super(record.primary_key)
          end
        end
      end
    end
  end
end
