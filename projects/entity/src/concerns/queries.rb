module Foobara
  class Entity < DetachedEntity
    module Concerns
      module Queries
        include Concern

        module ClassMethods
          def all(&)
            current_transaction_table.all(&)
          end

          def first
            # TODO: don't all queries need to do this???
            Foobara::Namespace.use entity_type do
              current_transaction_table.first
            end
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
          rescue ::Foobara::Persistence::EntityAttributesCrudDriver::Table::CannotFindError
            primary_key = if record.is_a?(Foobara::Entity)
                            record.primary_key
                          else
                            record
                          end

            raise NotFoundError.new(primary_key, entity_class: self)
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

          def that_owns(record, filters = [])
            containing_records = that_own(record, filters)

            unless containing_records.empty?
              if containing_records.size == 1
                containing_records.first
              else
                # :nocov:
                raise "Expected only one record to own #{record} but found #{containing_records.size}"
                # :nocov:
              end
            end
          end

          def that_own(record, filters = [])
            association_key = association_for([record.class, *filters])

            data_path = DataPath.new(association_key)

            done = false

            containing_records = Util.array(record)

            until done
              last = data_path.path.last

              if last == :"#"
                method = :find_all_by_attribute_containing_any_of
                attribute_name = data_path.path[-2]
                data_path = DataPath.new(data_path.path[0..-3])
              else
                method = :find_all_by_attribute_any_of
                attribute_name = last
                data_path = DataPath.new(data_path.path[0..-2])
              end

              containing_entity_class_path = data_path.to_s

              entity_class = if containing_entity_class_path.empty?
                               done = true
                               self
                             else
                               deep_associations[
                                 containing_entity_class_path
                               ].target_class
                             end

              containing_records = entity_class.send(method, attribute_name, containing_records).to_a

              done = true unless containing_records
            end

            containing_records
          end
        end
      end
    end
  end
end
