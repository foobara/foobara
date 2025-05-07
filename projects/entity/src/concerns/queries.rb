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
            if record.is_a?(Foobara::Entity)
              if record.loaded?
                record
              else
                current_transaction_table.load(record)
              end
            else
              current_transaction_table.load(record)
            end
          rescue ::Foobara::Persistence::EntityAttributesCrudDriver::Table::CannotFindError
            primary_key = if record.is_a?(Foobara::Entity)
                            record.primary_key
                          else
                            record
                          end

            raise NotFoundError.for(primary_key, entity_class: self)
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
            containing_records = that_own(record, filters).to_a

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

            possible_direct_owner_path = DataPath.new(association_key)

            # We need to find the second-to-last entity in the association path
            attribute_path = []
            owning_entity_class = nil

            begin
              attribute_path.unshift(possible_direct_owner_path.last)
              possible_direct_owner_path = DataPath.new(possible_direct_owner_path.path[0..-2])

              owning_entity_class = if possible_direct_owner_path.empty?
                                      self
                                    else
                                      deep_associations[possible_direct_owner_path.to_s]&.target_class
                                    end
            end until owning_entity_class

            if attribute_path.size == 1
              attribute_path = attribute_path.first
            end

            if owning_entity_class == self
              owning_entity_class.find_all_by_attribute(attribute_path, record)
            else
              Enumerator.new do |yielder|
                owners = owning_entity_class.find_all_by_attribute(attribute_path, record)

                owners.each do |owner|
                  that_own(owner, filters).each do |r|
                    yielder.yield(r)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
