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
              tracked_records << record
              mark_created(record)
            end

            def hard_deleted(record)
              if record.persisted?
                mark_hard_deleted(record)
                unmark_updated(record)
              else
                unmark_created(record)
                tracked_records.delete(record)
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
              # Hacky way to handle situation where the primary key might have changed.
              # TODO: make a better way of handling this.
              tracked_records.delete(record)
              tracked_records << record

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
              marked_hard_deleted.clear
              marked_updated.clear
              marked_created.clear
              tracked_records.clear
            end

            def reverted
              marked_hard_deleted.clear
              marked_updated.clear
              marked_created.clear
            end

            interesting_record_states = %i[
              updated
              hard_deleted
              created
              loading
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
