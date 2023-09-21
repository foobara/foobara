Foobara::Util.require_project_file("persistence/entity_attributes_crud_driver")

module Foobara
  module Persistence
    module EntityAttributesCrudDrivers
      class InMemory < EntityAttributesCrudDriver
        def open_connection(_connection_or_credentials)
          # TODO: figure out what we expect here when there is no connection necessary
          Object.new
        end

        def open_transaction
          # TODO: figure out what we expect here when there is no native transaction support
          Object.new
        end

        def close_transaction(_raw_tx)
          # can't fail since there's no native transaction support...
        end

        def rollback_transaction(_raw_tx)
          # nothing to do... except maybe enter a state where we don't flush anything else
          # but can just rely on higher-up plumbing for that
        end

        class Table < EntityAttributesCrudDriver::Table
          attr_accessor :records

          def initialize(...)
            @last_id = 0
            self.records = {}

            super
          end

          def get_id
            @last_id += 1
          end

          # CRUD
          # TODO: all multiple record methods should return enumerators and code further up should only use
          # the lazy enumerator interface... to encourage that/catch bugs we will return lazy enumerators in these
          # built-in crud drivers
          def all
            records.each_value.lazy
          end

          def count
            records.count
          end

          def find(record_id)
            records[record_id].deep_dup
          end

          def find!(record_id)
            attributes = find(record_id)

            unless attributes
              raise CannotFindError.new(record_id, "does not exist")
            end

            attributes
          end

          def insert(attributes)
            attributes = attributes.deep_dup

            record_id = record_id_for(attributes)

            if record_id.present?
              if exists?(record_id)
                raise CannotInsertError.new(record_id, "already exists")
              end
            else
              record_id = get_id
              attributes.merge!(primary_key_attribute => record_id)
            end

            records[record_id] = attributes
            find(record_id)
          end

          def update(attributes)
            record_id = record_id_for(attributes)

            unless exists?(record_id)
              # :nocov:
              raise CannotUpdateError.new(record_id, "does not exist")
              # :nocov:
            end

            records[record_id] = attributes.deep_dup
            find(record_id)
          end

          def hard_delete(record_id)
            unless exists?(record_id)
              # :nocov:
              raise CannotUpdateError.new(record_id, "does not exist")
              # :nocov:
            end

            records.delete(record_id)
          end

          def hard_delete_all
            self.records = {}
          end
        end
      end
    end
  end
end
