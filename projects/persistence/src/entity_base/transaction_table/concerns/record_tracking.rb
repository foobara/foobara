module Foobara
  module Persistence
    class EntityBase
      class TransactionTable
        module Concerns
          module RecordTracking
            attr_accessor :tracked_records, :records

            def initialize
              @records = {}
              self.tracked_records = WeakObjectSet.new(entity_class.primary_key_attribute)
              super
            end

            def loading(record)
              if loading?(record)
                # :nocov:
                raise "Already loading #{record}"
                # :nocov:
              end

              begin
                mark_loading(record)
                yield
              ensure
                unmark_loading(record)
              end

              record
            end

            def tracked(record)
              tracked_records << record
            end

            def created(record)
              tracked(record)
              mark_created(record)
            end

            def hard_deleted(record)
              if record.persisted?
                mark_hard_deleted(record)
                unmark_updated(record)
              else
                unmark_created(record)
              end
            end

            def unhard_deleted(record)
              unmark_hard_deleted(record)

              if record.dirty?
                mark_updated(record)
              end
            end

            def all_hard_deleted
              tracked_records.clear
              marked_hard_deleted.clear
              marked_updated.clear
              marked_created.clear
            end

            def updated(record)
              tracked(record)

              # TODO: is this check redundant? Maybe have the entity explode directly instead?
              if hard_deleted?(record)
                # :nocov:
                raise "Cannot update a hard deleted record"
                # :nocov:
              end

              unless created?(record)
                if record.dirty?
                  mark_updated(record)
                else
                  unmark_updated(record)
                end
              end
            end

            def rolled_back
              closed
            end

            def committed
              marked_persisted.each do |record|
                record.fire(:persisted)
              end

              closed
            end

            def closed
              marked_hard_deleted.clear
              marked_updated.clear
              marked_created.clear
              marked_loading.clear
            end

            # We need to clear this one separately. That's because otherwise a different table
            # might flush and create a thunk if it has an association to this table but we've stopped
            # tracking the record.
            def transaction_closed
              tracked_records.close
            end

            def reverted
              marked_hard_deleted.clear
              marked_updated.clear
              marked_created.clear
            end

            interesting_record_states = [
              :updated,
              :hard_deleted,
              :created,
              :loading,
              :persisted
            ]

            interesting_record_states.each do |state|
              define_method "mark_#{state}" do |record|
                set = records[state] ||= Set.new
                set << record
              end

              define_method "unmark_#{state}" do |record|
                if records.key?(state)
                  records[state].delete(record)
                end
              end

              define_method "#{state}?" do |record|
                records[state]&.include?(record)
              end

              # TODO: we should store created_at and updated_at and deleted_at with all of these records...
              define_method "marked_#{state}" do
                records[state] ||= Set.new
              end
            end
          end
        end
      end
    end
  end
end
