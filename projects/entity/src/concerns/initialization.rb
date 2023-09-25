module Foobara
  class Entity < Model
    class NoCurrentTransactionError < StandardError; end

    module Concerns
      module Initialization
        include Concern

        module ClassMethods
          def build(attributes)
            entity = __private_new__
            entity.write_attributes_without_callbacks(attributes)
            entity
          end

          def thunk(record_id)
            record_id = primary_key_type.process_value!(record_id)

            # TODO: is this possible?
            if record_id.nil?
              # :nocov:
              raise ArgumentError, "Primary key cannot be blank"
              # :nocov:
            end

            # check if tracked already...
            record = current_transaction_table.tracked_records.find_by_key(record_id)

            return record if record

            record = __new_with_transaction__
            record.is_persisted = true
            record.write_attributes_without_callbacks(primary_key_attribute => record_id)

            record.transaction.track_unloaded_thunk(record)
          end

          def loaded(attributes)
            attributes = attributes_type.process_value!(attributes)

            record_id = attributes[primary_key_attribute]

            record = current_transaction_table.tracked_records.find_by_key(record_id)

            if record
              raise "Already loaded for #{attributes}. Bug maybe?"
            end

            record = __new_with_transaction__
            record.successfully_loaded(attributes)

            record.transaction.track_loaded(record)

            unless record.primary_key
              raise "Expected primary key #{primary_key_attribute} to be present!"
            end

            record
          end

          def create(attributes = {})
            record = __new_with_transaction__

            record.write_attributes_without_callbacks(attributes)
            # can we eliminate this smell somehow?
            record.transaction.track_created(record)
          end

          def __new_with_transaction__
            record = __private_new__

            tx = Foobara::Persistence.current_transaction(self)

            unless tx
              raise Foobara::Entity::NoCurrentTransactionError,
                    "Cannot build #{entity_name} because not currently in a transaction."
            end

            record.transaction = tx

            record
          end
        end

        def successfully_loaded(attributes)
          if hard_deleted?
            raise "Not expecting to load a hard deleted record"
          end

          already_loaded = loaded?

          self.is_persisted = true
          self.is_loaded = true

          write_attributes_without_callbacks(attributes)

          save_persisted_attributes

          unless already_loaded
            fire(:loaded)
          end
        end

        def build(attributes = {})
          write_attributes_without_callbacks(attributes)
        end
      end
    end
  end
end
