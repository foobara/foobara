module Foobara
  class Entity < Model
    module Concerns
      module Transactions
        include Concern

        module ClassMethods
          def current_transaction_table
            Foobara::Persistence.current_transaction_table!(self)
          end

          def current_transaction
            Foobara::Persistence.current_transaction!(self)
          end

          def transaction(mode: nil, skip_dependent_transactions: false, &block)
            if skip_dependent_transactions
              entity_base.transaction(mode, &block)
            else
              Foobara::Persistence.transaction(
                self, *deep_depends_on,
                mode:,
                &block
              )
            end
          end
        end
      end
    end
  end
end
