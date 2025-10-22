module Foobara
  # Might be best to rename this to CrudDrivers or CrudDriver instead of Persistence?
  module Persistence
    class EntityAttributesCrudDriver
      attr_accessor :raw_connection, :tables, :table_prefix

      class << self
        def has_real_transactions?
          false
        end
      end

      def initialize(connection_or_credentials = nil, table_prefix: nil)
        self.table_prefix = table_prefix
        self.raw_connection = open_connection(connection_or_credentials)
        self.tables = {}
      end

      # Default behavior is for technologies that don't have a connection concept
      # in a proper sense
      def open_connection(_connection_or_credentials)
        # should we return some kind of Connection object here even if it does nothing interesting?
      end

      # Default behavior is for storage technologies that don't support proper
      # transaction support
      def open_transaction
        # Should we have some kind of fake transaction object that raises errors when used after rolledback/closed?
        Object.new
      end

      def flush_transaction(_raw_tx)
      end

      def revert_transaction(_raw_tx)
      end

      def rollback_transaction(_raw_tx)
      end

      def commit_transaction(_raw_tx)
      end

      def table_for(entity_class)
        key = entity_class.full_entity_name

        tables[key] ||= begin
          if table_prefix
            table_name = entity_class.entity_name
            table_name.gsub!(/^Types::/, "")

            table_name = Util.underscore(entity_class.entity_name)

            table_name = if table_prefix == true
                           "#{Util.underscore(entity_class.domain.scoped_full_name)}_#{table_name}"
                         else
                           "#{table_prefix}_#{table_name}"
                         end

            table_name.gsub!("::", "_")
          end

          # TODO: this seems like a smell
          Persistence.bases_need_sorting!
          self.class::Table.new(entity_class, self, table_name)
        end
      end

      # TODO: relocate this to another file?
      class Table
        class CannotCrudError < StandardError
          attr_accessor :record_id

          def verb
            match = /^Cannot(\w+)Error$/.match(Util.non_full_name(self.class))

            unless match
              # :nocov:
              raise "Bad error name for #{self.class.name}"
              # :nocov:
            end

            Util.underscore(match[1])
          end

          def initialize(record_id, submessage = nil)
            self.record_id = record_id
            message = "Could not #{verb} for id #{record_id.inspect}"

            if submessage
              message = "#{message}: #{submessage}"
            end

            super(message)
          end
        end

        class CannotFindError < CannotCrudError; end
        class CannotInsertError < CannotCrudError; end
        class CannotUpdateError < CannotCrudError; end
        class CannotDeleteError < CannotCrudError; end

        attr_accessor :table_name, :entity_class, :raw_connection, :crud_driver

        def initialize(entity_class, crud_driver, table_name = nil)
          if table_name.nil?
            table_name = Util.underscore(entity_class.entity_name)
            table_name.gsub!(/^types::/, "")
            table_name.gsub!("::", "_")
          end

          self.crud_driver = crud_driver
          self.entity_class = entity_class
          # what is this used for?
          self.raw_connection = crud_driver.raw_connection
          self.table_name = table_name
        end

        # CRUD
        def select(_query_declaration)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def all(page_size: nil)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def first
          all.first
        end

        def find(_record_id)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def find!(record_id)
          attributes = find(record_id)

          unless attributes
            raise CannotFindError.new(record_id, "does not exist")
          end

          attributes
        end

        def find_many!(record_ids)
          record_ids.each.lazy.map do |record_id|
            find!(record_id)
          end
        end

        def find_by_attribute_containing(attribute_name, value)
          found_type = entity_class.attributes_type.type_at_path("#{attribute_name}.#")

          if value
            value = restore_attributes(value, found_type)
          end

          all.find do |found_attributes|
            found_attributes[attribute_name].any? do |found_value|
              if found_value
                found_value = restore_attributes(found_value, found_type)
              end

              found_value == value
            end
          end
        end

        def find_all_by_attribute_any_of(attribute_name, values)
          all.select do |attributes|
            values.include?(attributes[attribute_name])
          end
        end

        def find_all_by_attribute_containing_any_of(attribute_name, values)
          all.select do |attributes|
            attributes[attribute_name]&.any? do |attribute_value|
              values.include?(attribute_value)
            end
          end
        end

        def find_by(attributes_filter)
          all.find do |found_attributes|
            matches_attributes_filter?(found_attributes, attributes_filter)
          end
        end

        def find_many_by(attributes_filter)
          Enumerator.new do |yielder|
            all.each do |found_attributes|
              if matches_attributes_filter?(found_attributes, attributes_filter)
                yielder << found_attributes
              end
            end
          end
        end

        def matches_attributes_filter?(attributes, attributes_filter)
          attributes_filter.all? do |attribute_name_or_path, value|
            # get the model-free type?
            attribute_type = entity_class.attributes_type.type_at_path(attribute_name_or_path)

            value = restore_attributes(value, attribute_type)

            if attribute_name_or_path.is_a?(::Array)
              values = DataPath.values_at(attribute_name_or_path, attributes)

              values.any? do |attribute_value|
                restore_attributes(attribute_value, attribute_type) == value
              end
            else
              attribute_value = DataPath.value_at(attribute_name_or_path, attributes)
              attribute_value = restore_attributes(attribute_value, attribute_type)
              attribute_value == value
            end
          end
        end

        def insert(_attributes)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def insert_many(attributes_array)
          # TODO: add a test for a driver that doesn't override this and remove these :nocov: comments
          # :nocov:
          attributes_array.each.lazy.map do |attributes|
            insert(attributes)
          end
          # :nocov:
        end

        def update(_record)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def hard_delete(_record_id)
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def hard_delete_many(record_ids)
          # TODO: add a test for a driver that doesn't override this and remove these :nocov: comments
          # :nocov:
          record_ids.each.lazy.map do |record_id|
            delete(record_id)
          end
          # :nocov:
        end

        def hard_delete_all!
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def count
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def exists?(record_id)
          !!find(record_id)
        end

        def all_exist?(record_ids)
          record_ids.all? do |record_id|
            exists?(record_id)
          end
        end

        def record_id_for(attributes)
          attributes&.[](primary_key_attribute)
        end

        def primary_key_attribute
          entity_class.primary_key_attribute
        end

        def restore_attributes(object, type = entity_class.attributes_type)
          if type.extends?(BuiltinTypes[:attributes])
            object.to_h do |attribute_name, attribute_value|
              attribute_type = type.type_at_path(attribute_name)
              [attribute_name.to_sym, restore_attributes(attribute_value, attribute_type)]
            end
          elsif type.extends?(BuiltinTypes[:tuple])
            # TODO: test this code path
            # :nocov:
            object.map.with_index do |value, index|
              element_type = type.element_types[index]
              restore_attributes(value, element_type)
            end
            # :nocov:
          elsif type.extends?(BuiltinTypes[:array])
            element_type = type.element_type
            object.map { |value| restore_attributes(value, element_type) }
          elsif type.extends?(BuiltinTypes[:entity])
            if object.is_a?(Model)
              if object.persisted?
                object = object.primary_key
                restore_attributes(object, type.target_class.primary_key_type)
              else
                object
              end
            else
              restore_attributes(object, type.target_class.primary_key_type)
            end
          elsif type.extends?(BuiltinTypes[:model])
            if object.is_a?(Model)
              object = object.attributes
            end
            restore_attributes(object, type.element_types)
          else
            outcome = type.process_value(object)

            if outcome.success?
              outcome.result
            else
              # TODO: figure out how to test this code path
              # :nocov:
              object
              # :nocov:
            end
          end
        end
      end
    end
  end
end
