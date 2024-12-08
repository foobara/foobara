module Foobara
  class Entity < DetachedEntity
    class CannotConvertRecordWithoutPrimaryKeyToJsonError < StandardError; end

    include Concerns::Callbacks
    include Concerns::Transactions
    include Concerns::Queries
    include Concerns::Mutations
    include Concerns::Attributes
    include Concerns::Persistence
    include Concerns::Initialization
    include Concerns::AttributeHelpers

    class << self
      prepend NewPrepend

      def full_entity_name
        full_model_name
      end

      def entity_name
        model_name
      end

      def allowed_subclass_opts
        [:primary_key, *super]
      end
    end

    foobara_delegate :full_entity_name, :entity_name, to: :class

    def dup
      # TODO: Maybe raise instead?
      self
    end

    def ==(other)
      # Should both records be required to be persisted to be considered equal when having matching primary keys?
      # For now we will consider them equal but it could make sense to consider them not equal.
      equal?(other) || (self.class == other.class && primary_key && primary_key == other.primary_key)
    end

    def hash
      (primary_key || object_id).hash
    end

    def inspect
      "<#{entity_name}:#{primary_key}>"
    end

    def to_json(*_args)
      primary_key&.to_json || raise(
        CannotConvertRecordWithoutPrimaryKeyToJsonError,
        "Cannot call record.to_json on unless record has a primary key. " \
        "Consider instead calling record.attributes.to_json instead."
      )
    end
  end
end
