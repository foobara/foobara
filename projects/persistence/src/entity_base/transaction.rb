module Foobara
  module Persistence
    class EntityBase
      class Transaction
        include Concerns::StateTransitions
        include Concerns::EntityCallbackHandling
        include Concerns::TransactionTracking

        attr_accessor :state_machine, :entity_base, :raw_tx, :tables, :is_nested

        def initialize(entity_base)
          self.entity_base = entity_base
          self.state_machine = StateMachine.new(owner: self)
          self.tables = {}
        end

        foobara_delegate :entity_attributes_crud_driver, to: :entity_base

        def create(entity_class, attributes = {})
          Persistence.to_base(entity_class).transaction(existing_transaction: self) do
            entity_class.create(attributes)
          end
        end

        def thunk(entity_class, record_id)
          Persistence.to_base(entity_class).transaction(existing_transaction: self) do
            entity_class.thunk(record_id)
          end
        end

        def loaded(entity_class, attributes)
          Persistence.to_base(entity_class).transaction(existing_transaction: self) do
            entity_class.loaded(attributes)
          end
        end

        def open?
          state_machine.currently_open?
        end

        def closed?
          state_machine.currently_closed?
        end

        def loading?(record)
          table_for(record).loading?(record)
        end

        def tracking?(record)
          table_for(record).tracking?(record)
        end

        def table_for(entity_class)
          if entity_class.is_a?(Entity)
            entity_class = entity_class.class
          end

          # TODO: so much passing self around...
          unless entity_base == entity_class.entity_base
            # :nocov:
            raise "#{entity_class} is from a different entity base! Cannot proceed."
            # :nocov:
          end

          tables[entity_class] ||= TransactionTable.new(self, entity_class)
        end

        def updated(record)
          table_for(record).updated(record)
        end

        def hard_deleted(record)
          table_for(record).hard_deleted(record)
        end

        def unhard_deleted(record)
          table_for(record).unhard_deleted(record)
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

        def load_aggregates(to_load_records)
          to_load = Set.new

          to_load_records.group_by(&:class).each_pair do |entity_class, records|
            unloaded = records.select { |record| record.persisted? && !record.loaded? }
            entity_class.current_transaction_table.load_many(unloaded)

            associations = entity_class.associations

            records.each do |record|
              associations.each_key do |data_path|
                # TODO: is there a more performant way to append an array to a set? probably.
                Foobara::DataPath.values_at(data_path, record).each do |value|
                  to_load << value
                end
              end
            end
          end

          unless to_load.empty?
            load_aggregates(to_load)
          end

          to_load_records
        end

        def load_aggregate(record)
          load_aggregates([record]).first
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

        # WARNING! this seems to bypass validations, hmmm....
        def flush_created_record!(record)
          table_for(record).flush_created_record!(record)
        end

        # convenience method...
        def perform(&)
          entity_base.using_transaction(self, &)
        end

        def nested?
          is_nested
        end
      end
    end
  end
end
