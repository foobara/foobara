module Foobara
  module Persistence
    class EntityBase
      class TransactionTable
        module Concerns
          # If something accesses the crud driver and manipulates records then it belongs in this concern.
          module Queries
            # TODO: why is this query method here but the rest are not?
            def all(&)
              enumerator = Enumerator.new do |yielder|
                tracked_records.each do |record|
                  next if record.hard_deleted?

                  # if the record is not loaded, it could be an unloaded thunk with a primary key to a row that has
                  # been deleted or maybe never even existed. So just exclude those and let them come from the
                  # database in the next loop
                  if created?(record) || record.loaded?
                    yielder << record
                  end
                end

                entity_attributes_crud_driver_table.all.each do |attributes|
                  primary_key = primary_key_for_attributes(attributes)
                  next if tracked_records.include_key?(primary_key)

                  yielder << entity_class.loaded(attributes)
                end
              end

              if block_given?
                enumerator.each(&)
              else
                enumerator.to_a
              end
            end
          end
        end
      end
    end
  end
end
