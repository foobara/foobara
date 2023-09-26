module Foobara
  module Persistence
    class EntityBase
      # TODO: move this under Transaction
      class TransactionTable
        class NoRecordFound < StandardError; end

        include Concerns::RecordTracking
        include Concerns::Queries

        attr_accessor :entity_attributes_crud_driver_table,
                      :entity_class,
                      :transaction

        def initialize(transaction, entity_class)
          self.transaction = transaction
          self.entity_class = entity_class
          self.entity_attributes_crud_driver_table = transaction.entity_attributes_crud_driver.table_for(entity_class)

          super()
        end

        def find_tracked(record_id)
          unless record_id
            # :nocov:
            raise ArgumentError, "Cannot use a blank primary key value"
            # :nocov:
          end

          if record_id.is_a?(::String) && record_id.empty?
            # :nocov:
            raise ArgumentError, "Cannot use a blank primary key value"
            # :nocov:
          end

          if record_id.is_a?(::Symbol) && record_id.to_s.empty?
            # :nocov:
            raise ArgumentError, "Cannot use a blank primary key value"
            # :nocov:
          end

          tracked_records.find_by_key(record_id)
        end

        def load(entity_or_record_id)
          if entity_or_record_id.is_a?(Entity)
            if entity_or_record_id.loaded?
              # :nocov:
              raise "#{entity_or_record_id} is already loaded!"
              # :nocov:
            end

            entity = tracked_records[entity_or_record_id]

            if entity && !entity.equal?(entity_or_record_id)
              # :nocov:
              raise "This transaction is already tracking a different entity with the same primary key." \
                    "Try passing in the primary key instead of constructing an unloaded entity to pass in."
              # :nocov:
            end

            record_id = entity.primary_key
          else
            record_id = entity_or_record_id

            if record_id.is_a?(::Hash)
              # :nocov:
              raise ArgumentError, "Unlikely that you meant to use a hash as a primary key"
              # :nocov:
            end

            unless record_id
              # :nocov:
              raise ArgumentError, "Cannot use a blank primary key value"
              # :nocov:
            end

            if record_id.is_a?(::String) && record_id.empty?
              # :nocov:
              raise ArgumentError, "Cannot use a blank primary key value"
              # :nocov:
            end

            if record_id.is_a?(::Symbol) && record_id.to_s.empty?
              # :nocov:
              raise ArgumentError, "Cannot use a blank primary key value"
              # :nocov:
            end

            entity = tracked_records.find_by_key(record_id)

            if entity&.loaded?
              return entity
            end
          end

          if entity
            loading(entity) do
              attributes = entity_attributes_crud_driver_table.find!(record_id)

              unless attributes
                # :nocov:
                raise NoRecordFound, "could not find record for #{entity_class.full_entity_name}:#{record_id}"
                # :nocov:
              end

              entity.successfully_loaded(attributes)
            end
          else
            attributes = entity_attributes_crud_driver_table.find!(record_id)

            unless attributes
              # :nocov:
              raise NoRecordFound, "could not find record for #{entity_class.full_entity_name}:#{record_id}"
              # :nocov:
            end

            transaction.loaded(entity_class, attributes)
          end
        end

        def load_many(record_ids_or_entities)
          to_load_record_ids = []
          entities = {}

          record_ids_or_entities.each do |entity_or_record_id|
            if entity_or_record_id.is_a?(Entity)
              if entity_or_record_id.loaded?
                # :nocov:
                raise "#{entity_or_record_id} is already loaded!"
                # :nocov:
              end

              entity = tracked_records[entity_or_record_id]

              if entity && !entity.equal?(entity_or_record_id)
                # :nocov:
                raise "This transaction is already tracking a different entity with the same primary key." \
                      "Try passing in the primary key instead of constructing an unloaded entity to pass in."
                # :nocov:
              end

              record_id = entity.primary_key
              to_load_record_ids << record_id
              entities[record_id] = entity
            else
              record_id = entity_or_record_id

              if record_id.is_a?(::Hash)
                # :nocov:
                raise ArgumentError, "Unlikely that you meant to use a hash as a primary key"
                # :nocov:
              end

              # TODO: encapsulate this record_id verification
              unless record_id
                # :nocov:
                raise ArgumentError, "Cannot use a blank primary key value"
                # :nocov:
              end

              if record_id.is_a?(::String) && record_id.empty?
                # :nocov:
                raise ArgumentError, "Cannot use a blank primary key value"
                # :nocov:
              end

              if record_id.is_a?(::Symbol) && record_id.to_s.empty?
                # :nocov:
                raise ArgumentError, "Cannot use a blank primary key value"
                # :nocov:
              end

              entity = tracked_records.find_by_key(record_id)

              if entity
                if entity.loaded?
                  entities[record_id] = entity
                end
              else
                entities[record_id] = entity_class.thunk(record_id)
                to_load_record_ids << record_id
              end
            end
          end

          entity_attributes_crud_driver_table.find_many!(to_load_record_ids).each do |attributes|
            record_id = primary_key_for_attributes(attributes)
            entity = entities[record_id]
            entity.successfully_loaded(attributes)
            entities[record_id] = entity
          end

          record_ids_or_entities.map do |record_id_or_entity|
            if record_id_or_entity.is_a?(Entity)
              record_id_or_entity
            else
              entities[record_id_or_entity]
            end
          end
        end

        def find_by_attribute(attribute_name, value)
          find_by(attribute_name => value)
        end

        def find_by_attribute_containing(attribute_name, value)
          value = entity_class.attributes_type.element_types[attribute_name].element_type.process_value!(value)

          tracked_records.each do |record|
            next if hard_deleted?(record)

            # TODO: what if there are multiple??
            if record.read_attribute(attribute_name).include?(value)
              return record
            end
          end

          found_attributes = entity_attributes_crud_driver_table.find_by_attribute_containing(
            attribute_name,
            to_persistable(value, false)
          )

          if found_attributes
            entity_class.loaded(found_attributes)
          end
        end

        def find_by(attributes_filter)
          attributes_filter = entity_class.attributes_type.process_value!(attributes_filter)
          attributes_filter = to_persistable(attributes_filter, false)

          tracked_records.each do |record|
            next if hard_deleted?(record)

            if entity_attributes_crud_driver_table.matches_attributes_filter?(record.attributes, attributes_filter)
              return record
            end
          end

          found_attributes = entity_attributes_crud_driver_table.find_by(attributes_filter)

          if found_attributes
            record_id = primary_key_for_attributes(found_attributes)

            record = find_tracked(record_id)
            return record if record

            entity_class.loaded(found_attributes)
          end
        end

        def find_many_by(attributes_filter)
          attributes_filter = entity_class.attributes_type.process_value!(attributes_filter)

          yielded_ids = Set.new

          Enumerator.new do |yielder|
            tracked_records.each do |record|
              next if hard_deleted?(record)

              if entity_attributes_crud_driver_table.matches_attributes_filter?(record.attributes, attributes_filter)
                yielded_ids << record.primary_key
                yielder << record
              end
            end

            entity_attributes_crud_driver_table.find_many_by(attributes_filter).each do |found_attributes|
              record_id = primary_key_for_attributes(found_attributes)

              next if yielded_ids.include?(record_id)

              record = find_tracked(record_id) || entity_class.loaded(found_attributes)

              yielder << record
            end
          end
        end

        def find_all_by_attribute_containing_any_of(attribute_name, values)
          values = Util.array(values)
          return [] if values.empty?

          value_type = entity_class.attributes_type.element_types[attribute_name].element_type

          values = values.map do |value|
            value_type.process_value!(value)
          end

          yielded_ids = Set.new

          Enumerator.new do |yielder|
            tracked_records.each do |record|
              next if hard_deleted?(record)

              record_values = record.read_attribute(attribute_name)
              next unless record_values
              next if record_values.empty?

              # TODO: what if there are multiple??
              values.each do |value|
                if record_values.include?(value)
                  yielded_ids << record.primary_key
                  yielder << record
                end
              end
            end

            values = values.map do |value|
              to_persistable(value, false)
            end

            entity_attributes_crud_driver_table.find_all_by_attribute_containing_any_of(
              attribute_name, values
            ).each do |found_attributes|
              record_id = primary_key_for_attributes(found_attributes)

              next if yielded_ids.include?(record_id)

              record = find_tracked(record_id) || entity_class.loaded(found_attributes)

              yielder << record
            end
          end
        end

        def find_all_by_attribute_any_of(attribute_name, values)
          values = Util.array(values)
          return [] if values.empty?

          value_type = entity_class.attributes_type.element_types[attribute_name]

          values = values.map do |value|
            value_type.process_value!(value)
          end

          yielded_ids = Set.new

          Enumerator.new do |yielder|
            tracked_records.each do |record|
              next if hard_deleted?(record)

              record_value = record.read_attribute(attribute_name)

              # TODO: what if there are multiple??
              if values.include?(record_value)
                yielded_ids << record.primary_key
                yielder << record
              end
            end

            values = values.map do |value|
              to_persistable(value, false)
            end

            entity_attributes_crud_driver_table.find_all_by_attribute_any_of(
              attribute_name, values
            ).each do |found_attributes|
              record_id = primary_key_for_attributes(found_attributes)

              next if yielded_ids.include?(record_id)

              record = find_tracked(record_id) || entity_class.loaded(found_attributes)

              yielder << record
            end
          end
        end

        def track_unloaded_thunk(record)
          tracked(record)
        end

        def track_created(entity)
          if entity.persisted?
            # :nocov:
            raise "Cannot insert #{entity} because it's already persisted."
            # :nocov:
          end

          created(entity)
        end

        def track_loaded(entity)
          tracked_records << entity
        end

        def hard_delete_all!
          tracked_records.each do |record|
            record.hard_delete! unless record.hard_deleted?
          end

          entity_attributes_crud_driver_table.hard_delete_all

          all_hard_deleted
        end

        def count
          persisted_count = entity_attributes_crud_driver_table.count

          persisted_count + marked_created.count - marked_hard_deleted.count
        end

        def exists?(record_id)
          record = tracked_records.find_by_key(record_id)
          # TODO: stamp the fact that it exists on the record somehow or in the record_tracking concern.

          (record && !record.hard_deleted? && (!record.persisted? || record.loaded?)) ||
            entity_attributes_crud_driver_table.exists?(record_id)
        end

        def all_exist?(record_ids)
          to_check_ids = record_ids.reject do |record_id|
            record = tracked_records.find_by_key(record_id)
            record && !record.hard_deleted? && (!record.persisted? || record.loaded?)
          end

          to_check_ids.empty? || entity_attributes_crud_driver_table.all_exist?(to_check_ids)
        end

        def primary_key_for_attributes(attributes)
          attributes[entity_class.primary_key_attribute]
        end

        def to_persistable(object, initial = true)
          case object
          when Entity
            if initial
              to_persistable(object.attributes, false)
            else
              object.primary_key
            end
          when ::Hash
            object.transform_values do |value|
              to_persistable(value, false)
            end
          when ::Array
            object.map do |element|
              to_persistable(element, false)
            end
          else
            object
          end
        end

        def flush_created!
          marked_created.each do |record|
            tracked_records.delete(record)

            flush_created_associations!(record)

            # TODO: do this in bulk
            attributes = entity_attributes_crud_driver_table.insert(to_persistable(record))
            record.write_attributes_without_callbacks(attributes)

            # we need to update finding the tracked object by key and removing/reading it seems to be the simplest
            # way to accomplish that at the moment
            tracked_records << record

            record.is_persisted = record.is_loaded = true
            record.save_persisted_attributes
          end

          marked_created.clear
        end

        def flush_created_record!(record)
          tracked_records.delete(record)

          flush_created_associations!(record)

          unmark_created(record)

          attributes = entity_attributes_crud_driver_table.insert(to_persistable(record))
          record.write_attributes_without_callbacks(attributes)

          # we need to update finding the tracked object by key and removing/reading it seems to be the simplest
          # way to accomplish that at the moment
          tracked_records << record

          record.is_persisted = record.is_loaded = true
          record.save_persisted_attributes
        end

        def flush_created_associations!(record)
          entity_class.associations.each_key do |association_data_path|
            DataPath.values_at(association_data_path, record).each do |associated_record|
              if transaction.created?(associated_record)
                transaction.flush_created_record!(associated_record)
              end
            end
          end
        end

        def flush_updated_and_hard_deleted!
          # TODO: use bulk operations to improve performance...
          marked_updated.each do |record|
            attributes = entity_attributes_crud_driver_table.update(to_persistable(record))
            record.write_attributes_without_callbacks(attributes)
            record.save_persisted_attributes
          end

          marked_updated.clear

          # TODO: use bulk operations to improve performance...
          marked_hard_deleted.each do |record|
            entity_attributes_crud_driver_table.hard_delete(record.primary_key)
            record.save_persisted_attributes
          end

          marked_hard_deleted.clear
        end

        def rollback!
          # TODO: could pause record tracking while doing this as a performance boost
          marked_updated.each(&:restore_without_callbacks!)
          marked_hard_deleted.each(&:restore_without_callbacks!)
          marked_created.each(&:hard_delete!)

          rolled_back
        end

        def revert!
          # TODO: could pause record tracking while doing this as a performance boost
          marked_updated.each(&:restore_without_callbacks!)
          marked_hard_deleted.each(&:restore_without_callbacks!)
          marked_created.each(&:restore_without_callbacks!)

          reverted
        end

        def tracking?(record)
          tracked_records.include?(record)
        end
      end
    end
  end
end
