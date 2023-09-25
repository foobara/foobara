module Foobara
  class Entity < Model
    module Concerns
      module Transactions
        include Concern

        module ClassMethods
          def current_transaction_table
            Foobara::Persistence.current_transaction_table(self)
          end

          def transaction(...)
            entity_base.transaction(...)
          end
        end
      end
    end
  end
end
