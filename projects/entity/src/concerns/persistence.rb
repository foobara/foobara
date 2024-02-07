module Foobara
  class Entity < Model
    module Concerns
      module Persistence
        class CannotUpdateHardDeletedRecordError < StandardError; end
        class UnknownIfPersisted < StandardError; end

        include Concern

        attr_accessor :is_loaded, :is_persisted, :is_hard_deleted, :is_built, :is_created, :persisted_attributes

        module ClassMethods
          def entity_base
            @entity_base ||= Foobara::Persistence.base_for_entity_class_name(full_entity_name)
          end
        end

        def hard_delete!
          hard_delete_without_callbacks!
          fire(:hard_deleted)
        end

        def hard_delete_without_callbacks!
          @is_hard_deleted = true
        end

        def save_persisted_attributes
          self.persisted_attributes = to_persisted_attributes(attributes)
        end

        def to_persisted_attributes(object)
          case object
          when ::Hash
            object.to_h do |k, v|
              [to_persisted_attributes(k), to_persisted_attributes(v)]
            end
          when ::Array
            object.map { |v| to_persisted_attributes(v) }
          else
            object.dup
          end
        end

        # Persisted means it is currently written to the database
        def persisted?
          is_persisted
        end

        def created?
          is_created
        end

        def loaded?
          is_loaded
        end

        # TODO: rename, maybe #detatched? or something?
        def built?
          is_built
        end

        def load_if_necessary!(attribute_name_or_attributes)
          return if built?
          return if loaded?
          return unless persisted?

          attribute_name = if attribute_name_or_attributes.is_a?(::Hash)
                             if attribute_name_or_attributes.keys.size == 1
                               attribute_name_or_attributes.keys.first.to_sym
                             end
                           elsif attribute_name_or_attributes
                             attribute_name_or_attributes.to_sym
                           end

          # TODO: are these symbols or not?
          return if attribute_name == primary_key_attribute.to_sym

          # TODO: how to get this out of here??
          transaction = Foobara::Persistence::EntityBase::Transaction.open_transaction_for(self)

          unless transaction
            raise NoCurrentTransactionError, "Trying to load a #{entity_name} outside of a transaction."
          end

          unless transaction.loading?(self)
            transaction.load(self)
          end
        end

        def verify_not_hard_deleted!
          if hard_deleted?
            raise CannotUpdateHardDeletedRecordError,
                  "Cannot make further updates to this record because it has been hard deleted"
          end
        end

        def unhard_delete!(skip_callbacks: false)
          self.is_hard_deleted = false

          unless skip_callbacks
            fire(:unhard_deleted)
          end
        end

        def restore!(skip_callbacks: false)
          if persisted?
            if hard_deleted?
              unhard_delete!(skip_callbacks:)
            end

            if loaded?
              if skip_callbacks
                write_attributes_without_callbacks(persisted_attributes)
              else
                write_attributes(persisted_attributes)
              end
            end
          else
            hard_delete!
          end
        end

        def restore_without_callbacks!
          restore!(skip_callbacks: true)
        end

        def dirty?
          return true unless persisted?
          return false unless loaded?

          persisted_attributes != to_persisted_attributes(attributes)
        end

        def hard_deleted?
          @is_hard_deleted
        end
      end
    end
  end
end
