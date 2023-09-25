module Foobara
  class Entity < Model
    include Concerns::Callbacks
    include Concerns::Associations
    include Concerns::Transactions
    include Concerns::Queries
    include Concerns::Types
    include Concerns::Attributes
    include Concerns::PrimaryKey
    include Concerns::Persistence
    include Concerns::Initialization

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

    # simplify this initialize stuff by avoiding .new() for multiple use cases
    # TODO: eliminate validate here??
    def initialize(*args, validate: false, outside_transaction: false, **opts)
      arg = Util.args_and_opts_to_opts(args, opts)

      unless outside_transaction
        tx = Persistence.current_transaction(self)

        unless tx
          raise NoCurrentTransactionError, "Cannot build #{entity_name} because not currently in a transaction."
        end
      end

      without_callbacks do
        if args.empty? || arg.is_a?(::Hash)
          super(arg, validate:)
          # can we eliminate this smell somehow?
          tx&.create(self)

          self.is_persisted = false
        else
          super(nil, validate:)

          if arg.nil?
            # :nocov:
            raise ArgumentError, "Primary key cannot be blank"
            # :nocov:
          end

          self.is_persisted = true

          build(primary_key_attribute => arg)

          tx&.track_unloaded_thunk(self)
        end
      end
    end

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
  end
end
