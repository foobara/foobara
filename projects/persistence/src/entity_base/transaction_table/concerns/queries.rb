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
                  # if the record is not loaded, it could be an unloaded thunk with a primary key to a row that has
                  # been deleted or maybe never even existed. So just exclude those and let them come from the
                  # database in the next loop
                  if !record.hard_deleted? && (created?(record) || record.loaded?)
                    yielder << record
                  end
                end

                entity_attributes_crud_driver_table.all.each do |attributes|
                  attributes = normalize_attributes(attributes)
                  primary_key = primary_key_for_attributes(attributes)

                  if tracked_records.include_key?(primary_key)
                    record = tracked_records.find_by_key(primary_key)

                    next if record.hard_deleted?
                    next if created?(record)

                    unless record.loaded?
                      load(record)
                      yielder << record
                      next
                    end

                    next
                  end

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
