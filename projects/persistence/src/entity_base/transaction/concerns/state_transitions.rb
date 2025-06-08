module Foobara
  module Persistence
    class EntityBase
      class Transaction
        # Used to communicate to enclosing transaction that execution has terminated and the transaction is borked
        class RolledBack < StandardError; end

        module Concerns
          module StateTransitions
            foobara_delegate :close!, :currently_open?, to: :state_machine

            def open!
              state_machine.open! do
                self.raw_tx = entity_attributes_crud_driver.open_transaction
              end
            end

            def flush!
              state_machine.flush! do
                each_table(&:validate!)
                each_table(&:flush_created!)
                each_table(&:flush_updated_and_hard_deleted!)
              end
              entity_attributes_crud_driver.flush_transaction(raw_tx)
            rescue => e
              # :nocov:
              rollback!(e)
              raise
              # :nocov:
            end

            # Should communicate somehow that this is only in-memory.
            # TODO: support multiple-reverts for databases that support checkpoints
            def revert!
              state_machine.revert! do
                each_table(&:revert!)
              end
              entity_attributes_crud_driver.revert_transaction(raw_tx)
            rescue => e
              # :nocov:
              rollback!(e)
              raise
              # :nocov:
            end

            def commit!
              state_machine.commit! do
                each_table(&:validate!)
                each_table(&:flush_created!)
                each_table(&:flush_updated_and_hard_deleted!)
                entity_attributes_crud_driver.commit_transaction(raw_tx)
              end
            rescue => e
              # :nocov:
              rollback!(e)
              raise
              # :nocov:
            end

            # TODO: this belongs elsewhere
            def each_table(&)
              tables.values.each(&)
            end

            def rollback!(because_of = nil)
              state_machine.rollback! do
                # TODO: raise error if already flushed and if crud_driver doesn't support true transactions
                entity_attributes_crud_driver.rollback_transaction(raw_tx)
                each_table(&:rollback!)
              end

              if !because_of && (self == entity_base.current_transaction)
                raise RolledBack, "intentionally rolled back"
              end
            rescue
              state_machine.error! if state_machine.currently_open?
              raise
            end
          end
        end
      end
    end
  end
end
