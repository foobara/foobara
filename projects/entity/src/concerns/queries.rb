module Foobara
  class Entity < Model
    module Concerns
      module Queries
        include Concern

        module ClassMethods
          def all(&)
            current_transaction_table.all(&)
          end

          def find_by_attribute(attribute_name, value)
            current_transaction_table.find_by_attribute(attribute_name, value)
          end

          def find_all_by_attribute(attribute_name, value)
            current_transaction_table.find_all_by_attribute(attribute_name, value)
          end

          def find_by_attribute_containing(attribute_name, value)
            current_transaction_table.find_by_attribute_containing(attribute_name, value)
          end

          def find_all_by_attribute_containing_any_of(attribute_name, values)
            current_transaction_table.find_all_by_attribute_containing_any_of(attribute_name, values)
          end

          def find_all_by_attribute_any_of(attribute_name, values)
            current_transaction_table.find_all_by_attribute_any_of(attribute_name, values)
          end

          def find_by(attributes)
            current_transaction_table.find_by(attributes)
          end

          def find_many_by(attributes)
            current_transaction_table.find_many_by(attributes)
          end

          def load(record)
            if !record.is_a?(Foobara::Entity) || !record.loaded?
              current_transaction_table.load(record)
            end
          end

          def load_aggregate(record_or_record_id)
            record = if record_or_record_id.is_a?(Entity)
                       record_or_record_id
                     else
                       thunk(record_or_record_id)
                     end

            current_transaction.load_aggregate(record)
          end

          def load_many(*record_ids)
            if record_ids.size == 1 && record_ids.first.is_a?(::Array)
              record_ids = record_ids.first
            end

            current_transaction_table.load_many(record_ids)
          end

          def all_exist?(record_ids)
            # TODO: support splat
            current_transaction_table.all_exist?(record_ids)
          end

          def exists?(record_id)
            # TODO: support splat
            current_transaction_table.exists?(record_id)
          end

          def count
            current_transaction_table.count
          end
        end
      end
    end
  end
end
