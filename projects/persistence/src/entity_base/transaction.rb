module Foobara
  module Persistence
    class EntityBase
      class Transaction
        include Concerns::StateTransitions

        attr_accessor :state_machine, :entity_base, :raw_tx, :tables

        def initialize(entity_base)
          self.entity_base = entity_base
          self.state_machine = StateMachine.new
          self.tables = {}
        end

        foobara_delegate :entity_attributes_crud_driver, to: :entity_base

        def open?
          state_machine.currently_open?
        end

        def closed?
          state_machine.currently_closed?
        end

        def loading?(record)
          table_for(record).loading?(record)
        end

        def table_for(entity_class)
          if entity_class.is_a?(Entity)
            entity_class = entity_class.class
          end

          # TODO: so much passing self around...
          tables[entity_class] ||= TransactionTable.new(self, entity_class)
        end

        def truncate!
          each_table(&:hard_delete_all!)
        end

        def hard_delete_all!(entity_class)
          table_for(entity_class).hard_delete_all!
        end

        def load(record_or_entity_class, record_id = nil)
          entity_or_id = if record_or_entity_class.is_a?(Entity)
                           if record_id
                             # :nocov:
                             raise ArgumentError, "Do not give a record_id when also giving a record"
                             # :nocov:
                           end

                           record_or_entity_class
                         else
                           unless record_id
                             # :nocov:
                             raise ArgumentError, "Must give a record_id when passing in an entity class"
                             # :nocov:
                           end

                           record_id
                         end

          table_for(record_or_entity_class).load(entity_or_id)
        end

        def track_unloaded_thunk(entity)
          table_for(entity).track_unloaded_thunk(entity)
        end

        def track_loaded(entity)
          table_for(entity).track_loaded(entity)
        end

        def track_created(entity)
          table_for(entity).track_created(entity)
        end

        def created?(record)
          table_for(record).created?(record)
        end

        def flush_created_record!(record)
          table_for(record).flush_created_record!(record)
        end
      end
    end
  end
end
