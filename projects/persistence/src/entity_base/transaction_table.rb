module Foobara
  module Persistence
    class InvalidRecordError < StandardError
      attr_accessor :record

      def initialize(record)
        self.record = record

        super("Cannot persist invalid record #{record}: #{record.validation_errors}")
      end
    end

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

        def first
          found_attributes = normalize_attributes(entity_attributes_crud_driver_table.first)

          if found_attributes
            record_id = primary_key_for_attributes(found_attributes)

            record = tracked_records.find_by_key(record_id) || transaction.loaded(entity_class, found_attributes)

            record || marked_created.first
          end
        end

        def load(entity_or_record_id)
          if entity_or_record_id.nil?
            # :nocov:
            raise "Expected a record or record primary key but received nil"
            # :nocov:
          end

          if entity_or_record_id.is_a?(Entity)
            entity = if entity_or_record_id.persisted?
                       unless entity_or_record_id.primary_key
                         # :nocov:
                         raise "Did not expect a record to be persisted but have no primary key"
                         # :nocov:
                       end

                       tracked_records.find_by_key(entity_or_record_id.primary_key)
                     else
                       # :nocov:
                       raise "Cannot load an unpersisted record!"
                       # :nocov:
                     end

            # rubocop:disable Lint/IdentityComparison
            if entity &&
               (!entity.equal?(entity_or_record_id) || entity.object_id != entity_or_record_id.object_id)
              # :nocov:
              raise "This transaction is already tracking a different entity with the same primary key." \
                    "Try passing in the primary key instead of constructing an unloaded entity to pass in."
              # :nocov:
            end
            # rubocop:enable Lint/IdentityComparison

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
              attributes = normalize_attributes(entity_attributes_crud_driver_table.find!(record_id))

              unless attributes
                # :nocov:
                raise NoRecordFound, "could not find record for #{entity_class.full_entity_name}:#{record_id}"
                # :nocov:
              end

              entity.successfully_loaded(attributes)
            end
          else
            attributes = normalize_attributes(entity_attributes_crud_driver_table.find!(record_id))

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
                next
              end

              entity = if entity_or_record_id.persisted?
                         unless entity_or_record_id.primary_key
                           # :nocov:
                           raise "Did not expect a record to be persisted but have no primary key"
                           # :nocov:
                         end

                         tracked_records.find_by_key(entity_or_record_id.primary_key)
                       else
                         # :nocov:
                         raise "Cannot load an unpersisted record!"
                         # :nocov:
                       end

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
            attributes = normalize_attributes(attributes)
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

        def find_all_by_attribute(attribute_name_or_path, value)
          find_many_by(attribute_name_or_path => value)
        end

        def find_by_attribute_containing(attribute_name, value)
          value = entity_class.attributes_type.element_types[attribute_name].element_type.process_value!(value)

          tracked_records.each do |record|
            next unless record.loaded? || record.created?
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
            found_attributes = normalize_attributes(found_attributes)
            record_id = primary_key_for_attributes(found_attributes)

            record = find_tracked(record_id)

            if record
              # was already considered among tracked records if loaded? is true so do not return it as
              # it has changed and no longer matches
              unless record.loaded?
                loading(record) do
                  record.successfully_loaded(found_attributes)
                end
              end
            else
              entity_class.loaded(found_attributes)
            end
          end
        end

        def find_by(attributes_filter)
          element_types = entity_class.attributes_type.element_types

          attributes_filter = attributes_filter.to_h do |attribute_name, value|
            [attribute_name, element_types[attribute_name].process_value!(value)]
          end

          tracked_records.each do |record|
            next unless record.loaded? || record.created?
            next if hard_deleted?(record)

            if entity_attributes_crud_driver_table.matches_attributes_filter?(record.attributes, attributes_filter)
              return record
            end
          end

          found_attributes_enumerator = entity_attributes_crud_driver_table.find_many_by(attributes_filter)

          found_attributes_enumerator.each do |found_attributes|
            found_attributes = normalize_attributes(found_attributes)
            record_id = primary_key_for_attributes(found_attributes)

            record = find_tracked(record_id)

            if record
              if record.loaded?
                # was already considered among tracked records if loaded? is true so do not return it as
                # it has changed and no longer matches
                # TODO: figure out how to test this code path
                # :nocov:
                record = nil
                # :nocov:
              else
                loading(record) do
                  record.successfully_loaded(found_attributes)
                end
              end
            else
              record = entity_class.loaded(found_attributes)
            end

            if record
              return record
            end
          end

          nil
        end

        def find_many_by(attributes_filter)
          find_by_type = entity_class.domain.foobara_type_from_declaration(entity_class.attributes_for_find_by)

          path_filters = {}
          regular_filters = {}

          attributes_filter.each_pair do |attribute_name_or_path, value|
            case attribute_name_or_path
            when ::Symbol, ::String
              regular_filters[attribute_name_or_path] = value
            when ::Array, Value::DataPath
              path_filters[attribute_name_or_path] = value
            else
              # :nocov:
              raise "Unexpected filter type: #{attribute_name_or_path.class}"
              # :nocov:
            end
          end

          regular_filters = find_by_type.process_value!(regular_filters)

          path_filters.keys.each do |path|
            type = entity_class.deep_associations[DataPath.for(path).to_s]
            path_filters[path] = type.process_value!(path_filters[path])
          end

          attributes_filter = regular_filters.merge(path_filters)

          yielded_ids = Set.new

          Enumerator.new do |yielder|
            tracked_records.each do |record|
              next if hard_deleted?(record)
              next unless record.loaded? || record.built? || record.created?

              if entity_attributes_crud_driver_table.matches_attributes_filter?(record.attributes, attributes_filter)
                yielded_ids << record.primary_key
                yielder << record
              end
            end

            entity_attributes_crud_driver_table.find_many_by(attributes_filter).each do |found_attributes|
              found_attributes = normalize_attributes(found_attributes)
              record_id = primary_key_for_attributes(found_attributes)

              next if yielded_ids.include?(record_id)

              record = find_tracked(record_id)

              if record
                if record.loaded?
                  # was already considered among tracked records if loaded? is true so do not return it as
                  # it has changed and no longer matches
                  # TODO: figure out how to test this code path
                  # :nocov:
                  record = nil
                  # :nocov:
                else
                  loading(record) do
                    record.successfully_loaded(found_attributes)
                  end
                end
              else
                record = entity_class.loaded(found_attributes)
              end

              if record
                yielder << record
              end
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
              next unless record.loaded? || record.created?
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
              found_attributes = normalize_attributes(found_attributes)
              record_id = primary_key_for_attributes(found_attributes)

              next if yielded_ids.include?(record_id)

              record = find_tracked(record_id)

              if record
                # TODO: test this code path
                # :nocov:
                if record.loaded?
                  # was already considered among tracked records if loaded? is true so do not return it as
                  # it has changed and no longer matches
                  record = nil
                else
                  loading(record) do
                    record.successfully_loaded(found_attributes)
                  end
                end
                # :nocov:
              else
                record = entity_class.loaded(found_attributes)
              end

              if record
                yielder << record
              end
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
              next unless record.loaded? || record.created?
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
              found_attributes = normalize_attributes(found_attributes)
              record_id = primary_key_for_attributes(found_attributes)

              next if yielded_ids.include?(record_id)

              record = find_tracked(record_id)

              if record
                # TODO: test this code path
                # :nocov:
                if record.loaded?
                  # was already considered among tracked records if loaded? is true so do not return it as
                  # it has changed and no longer matches
                  record = nil
                else
                  loading(record) do
                    record.successfully_loaded(found_attributes)
                  end
                end
                # :nocov:
              else
                record = entity_class.loaded(found_attributes)
              end

              if record
                yielder << record
              end
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
          tracked(entity)
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
          when Model
            to_persistable(object.attributes, false)
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

        def validate!
          marked_created.each do |record|
            unless record.valid?
              raise InvalidRecordError, record
            end
          end

          marked_updated.each do |record|
            unless record.valid?
              raise InvalidRecordError, record
            end
          end
        end

        def flush_created!
          marked_created.each do |record|
            # TODO: do this in bulk
            attributes = entity_attributes_crud_driver_table.insert(to_persistable(record))
            primary_key_attribute = entity_class.primary_key_attribute
            primary_key = attributes[primary_key_attribute]

            record.write_attributes_without_callbacks(primary_key_attribute => primary_key)

            # we need to update finding the tracked object by key and removing/reading it seems to be the simplest
            # way to accomplish that at the moment
            tracked(record)

            record.is_persisted = record.is_loaded = true
            record.is_created = false
            record.save_persisted_attributes
          end

          marked_created.clear
        end

        def flush_updated_and_hard_deleted!
          # TODO: use bulk operations to improve performance...
          marked_updated.each do |record|
            entity_attributes_crud_driver_table.update(to_persistable(record))
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
          # is it really safe to do this without callbacks?? What about other systems listening
          # to those callbacks? This feels wrong.
          # TODO: fix this
          marked_updated.each(&:restore_without_callbacks!)
          marked_hard_deleted.each(&:restore_without_callbacks!)
          marked_created.each(&:hard_delete_without_callbacks!)

          rolled_back
        end

        def commit!
          validate!
          flush_created!
          flush_updated_and_hard_deleted!

          committed
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

        private

        def normalize_attributes(attributes)
          if attributes
            attributes = attributes.transform_keys(&:to_sym)

            primary_key_name = entity_class.primary_key_attribute
            primary_key_value = attributes[primary_key_name]

            attributes[primary_key_name] = entity_class.primary_key_type.cast!(primary_key_value)

            attributes
          end
        end
      end
    end
  end
end
