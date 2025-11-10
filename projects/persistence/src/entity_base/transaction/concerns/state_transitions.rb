module Foobara
  module Persistence
    class EntityBase
      class Transaction
        # Used to communicate to enclosing transaction that execution has terminated and the transaction is borked
        class RolledBack < StandardError; end

        module Concerns
          module StateTransitions
            def currently_open?
              state_machine.currently_open?
            end

            def open!
              state_machine.open! do
                self.raw_tx = entity_attributes_crud_driver.open_transaction
              end
            end

            def open_nested!(outer_tx)
              state_machine.open_nested! do
                self.is_nested = true
                self.raw_tx = outer_tx.raw_tx
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
              return commit_nested! if nested?

              state_machine.commit! do
                each_table(&:commit!)
                entity_attributes_crud_driver.commit_transaction(raw_tx)
                each_table(&:committed)
                each_table(&:transaction_closed)
              end
            rescue => e
              # :nocov:
              rollback!(e)
              raise
              # :nocov:
            end

            def commit_nested!
              state_machine.commit_nested! do
                each_table(&:commit!)
                entity_attributes_crud_driver.flush_transaction(raw_tx)
                each_table(&:transaction_closed)
              end
            rescue => e
              # :nocov:
              rollback!(e)
              raise
              # :nocov:
            end

            # TODO: this belongs elsewhere
            def each_table(&)
              @ordered_tables ||= if tables.size <= 1
                                    tables.values
                                  else
                                    entity_class_to_table = {}
                                    entity_classes = []

                                    tables.each_value do |table|
                                      entity_class = table.entity_class
                                      entity_classes << entity_class
                                      entity_class_to_table[entity_class] = table
                                    end

                                    ordered_entity_classes = EntityBase.order_entity_classes(entity_classes)

                                    ordered_entity_classes.map do |entity_class|
                                      entity_class_to_table[entity_class]
                                    end
                                  end

              @ordered_tables.each(&)
            end

            def rollback!(because_of = nil)
              return rollback_nested!(because_of) if nested?

              state_machine.rollback! do
                # TODO: raise error if already flushed and if crud_driver doesn't support true transactions
                entity_attributes_crud_driver.rollback_transaction(raw_tx)
                each_table(&:rollback!)
              end

              each_table(&:transaction_closed)

              if !because_of && (self == entity_base.current_transaction)
                raise RolledBack, "intentionally rolled back"
              end
            rescue
              state_machine.error! if state_machine.currently_open?
              raise
            end

            def rollback_nested!(because_of = nil)
              state_machine.rollback_nested! do
                entity_attributes_crud_driver.revert_transaction(raw_tx)
                each_table(&:revert!)
              end

              each_table(&:transaction_closed)

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
