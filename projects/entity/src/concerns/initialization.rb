module Foobara
  class Entity < DetachedEntity
    class NoCurrentTransactionError < StandardError; end

    module Concerns
      module Initialization
        include Concern

        module ClassMethods
          def can_be_created_through_casting?
            true
          end

          def build(attributes)
            record = __private_new__
            record.build(attributes)
            # TODO: rename to something like "detached"
            record.is_built = true
            record.is_loaded = false

            record.fire(:initialized)
            record.fire(:initialized_built)

            record
          end

          def thunk(record_id)
            record_id = primary_key_type.process_value!(record_id)

            # TODO: is this possible?
            if record_id.nil?
              # :nocov:
              raise ArgumentError, "Primary key cannot be blank"
              # :nocov:
            end

            # check if tracked already...
            record = current_transaction_table.find_tracked(record_id)

            return record if record

            record = __private_new__
            record.is_loaded = false
            record.is_persisted = true
            record.write_attributes_without_callbacks(primary_key_attribute => record_id)

            record.fire(:initialized)
            record.fire(:initialized_thunk)

            record
          end

          def loaded(attributes)
            attributes = attributes_type.process_value!(attributes)

            record_id = attributes[primary_key_attribute]

            record = current_transaction_table.find_tracked(record_id)

            if record
              # :nocov:
              raise "Already loaded for #{attributes}. Bug maybe?"
              # :nocov:
            end

            record = __private_new__

            record.successfully_loaded(attributes)

            unless record.primary_key
              # :nocov:
              raise "Expected primary key #{primary_key_attribute} to be present!"
              # :nocov:
            end

            record.fire(:initialized)
            record.fire(:initialized_loaded)

            record
          end

          def create(attributes = {})
            record = __private_new__
            record.is_created = true
            record.is_loaded = false

            defaults = attributes_type.declaration_data[:defaults]
            if defaults && !defaults.empty?
              resolved_defaults = defaults.transform_values do |value|
                value.is_a?(Proc) ? value.call : value
              end
              record.write_attributes_without_callbacks(resolved_defaults)
            end

            record.write_attributes_without_callbacks(attributes)

            # TODO: delete :initialized if unused
            record.fire(:initialized)
            record.fire(:initialized_created)

            record
          end
        end

        def successfully_loaded(attributes)
          if hard_deleted?
            # :nocov:
            raise "Not expecting to load a hard deleted record"
            # :nocov:
          end

          # TODO: why would we proceed if this is the case? Maybe raise?
          already_loaded = loaded?

          self.is_persisted = true
          self.is_loaded = true

          write_attributes_without_callbacks(attributes)

          save_persisted_attributes

          unless already_loaded
            fire(:loaded)
          end
        end

        def build(attributes = {})
          write_attributes_without_callbacks(attributes)
        end
      end
    end
  end
end
