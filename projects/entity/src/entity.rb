# TODO: move to separate file
module Foobara
  class Entity < Model
    module FindExistingRecordIfExists
      def new(*args, validate: false, outside_transaction: false, **opts)
        arg = Util.args_and_opts_to_opts(args, opts)

        if arg.is_a?(::Hash)
          super(arg, validate:, outside_transaction:)
        elsif outside_transaction
          super(arg, outside_transaction: true)
        else
          current_transaction_table.find_tracked(arg) || super(arg)
        end
      end
    end
  end
end

module Foobara
  # TODO: either make this an abstract base class of ValueModel and Entity or rename it to ValueModel
  # and have Entity inherit from it...
  # should we have a state machine here??
  # init:
  #   created
  #     persisted
  #   loaded
  class Entity < Model
    class UnexpectedPrimaryKeyChangeError < StandardError; end
    class NoCurrentTransactionError < StandardError; end
    class CurrentTransactionIsClosed < StandardError; end
    class CannotUpdateHardDeletedRecordError < StandardError; end
    class UnknownIfPersisted < StandardError; end

    include Concerns::Callbacks

    class << self
      prepend FindExistingRecordIfExists

      def associations
        @associations ||= construct_associations
      end

      def construct_associations(type = attributes_type, path = DataPath.new, result = {})
        if entity_type?(type)
          result[path.to_s] = type
        elsif array_type?(type)
          # TODO: what to do about an associative array type?? Unclear how to make a key from that...
          # TODO: raise if associative array contains a non-persisted record to handle this edge case for now.
          construct_associations(type.element_type, path.append(:"#"), result)
        elsif attributes_type?(type)
          type.element_types.each_pair do |attribute_name, element_type|
            construct_associations(element_type, path.append(attribute_name), result)
          end
        elsif associative_array_type?(type)
          # not going to bother testing this for now
          # :nocov:
          if contains_associations?(type)
            raise "Associative array types with associations in them are not currently supported. " \
                  "Use attributes type if you can or set the key_type and/or value_type to duck type"
          end
          # :nocov:
        end

        result
      end

      def entity_type
        model_type
      end

      def contains_associations?(type = entity_type, initial = true)
        if entity_type?(type)
          if initial
            contains_associations?(type.element_types, false)
          else
            true
          end
        elsif array_type?(type)
          # TODO: what to do about an associative array type?? Unclear how to make a key from that...
          # TODO: raise if associative array contains a non-persisted record to handle this edge case for now.
          contains_associations?(type.element_type, false)
        elsif attributes_type?(type)
          type.element_types.values.any? do |element_type|
            contains_associations?(element_type, false)
          end
        elsif associative_array_type?(type)
          # not going to bother testing this for now
          # :nocov:
          contains_associations?(type.key_type, false) || contains_associations?(type.value_type, false)
          # :nocov:
        end
      end

      # TODO: these don't really belong on this class...
      def type_extends?(type, symbol)
        type.extends_type?(namespace.type_for_symbol(symbol))
      end

      def attributes_type?(type)
        type_extends?(type, :attributes)
      end

      def associative_array_type?(type)
        type_extends?(type, :associative_array)
      end

      def array_type?(type)
        type_extends?(type, :array)
      end

      def entity_type?(type)
        type_extends?(type, :entity)
      end

      def current_transaction_table
        Foobara::Persistence.current_transaction_table(self)
      end

      def build(attributes_or_id)
        new(attributes_or_id, outside_transaction: true)
      end

      def all(&)
        current_transaction_table.all(&)
      end

      def find_by(attributes)
        current_transaction_table.find_by(attributes)
      end

      def find_many_by(attributes)
        current_transaction_table.find_many_by(attributes)
      end

      def load(record_id)
        current_transaction_table.load(record_id)
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

      def transaction(...)
        entity_base.transaction(...)
      end

      def entity_base
        @entity_base ||= Persistence.base_for_entity_class_name(full_entity_name)
      end

      def type_declaration(...)
        raise "No primary key set yet" unless primary_key_attribute

        super.merge(type: :entity, primary_key: primary_key_attribute)
      end

      attr_reader :primary_key_attribute

      def primary_key(attribute_name)
        if primary_key_attribute
          # :nocov:
          raise "Primary key already set to #{primary_key_attribute}"
          # :nocov:
        end

        if attribute_name.nil? || attribute_name.empty?
          # :nocov:
          raise ArgumentError, "Primary key can't be blank"
          # :nocov:
        end

        @primary_key_attribute = attribute_name.to_sym

        set_model_type
      end

      def set_model_type
        if primary_key_attribute
          super
        end
      end

      def full_entity_name
        full_model_name
      end

      def entity_name
        model_name
      end

      def primary_key_type
        @primary_key_type ||= attributes_type.element_types[primary_key_attribute]
      end

      def allowed_subclass_opts
        [:primary_key, *super]
      end
    end

    attr_accessor :transaction, :is_loaded, :is_persisted, :is_hard_deleted, :persisted_attributes

    foobara_delegate :primary_key_attribute, :full_entity_name, :entity_name, to: :class

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

    def without_callbacks
      old_callbacks_enabled = @callbacks_disabled

      begin
        @callbacks_disabled = true
        yield
      ensure
        @callbacks_disabled = old_callbacks_enabled
      end
    end

    def hard_delete!
      @is_hard_deleted = true
      fire(:hard_deleted)
    end

    def build(attributes = {})
      write_attributes_without_callbacks(attributes)
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

    def dup
      self
    end

    # Persisted means it is currently written to the database
    def persisted?
      is_persisted
    end

    def loaded?
      @is_loaded
    end

    def ==(other)
      # Should both records be required to be persisted to be considered equal when having matching primary keys?
      # For now we will consider them equal but it could make sense to consider them not equal.
      equal?(other) || (self.class == other.class && primary_key && primary_key == other.primary_key)
    end

    def hash
      (primary_key || object_id).hash
    end

    def primary_key
      read_attribute(primary_key_attribute)
    end

    def read_attribute(attribute_name)
      load_if_necessary!(attribute_name)
      super
    end

    def read_attribute!(attribute_name)
      load_if_necessary!(attribute_name)
      super
    end

    def load_if_necessary!(attribute_name_or_attributes)
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

      unless transaction.loading?(self)
        transaction.load(self)
      end
    end

    def verify_transaction_is_open!
      if transaction && !transaction.open?
        # :nocov:
        raise CurrentTransactionIsClosed,
              "Cannot make further updates to this record because the transaction has been closed."
        # :nocov:
      end
    end

    def verify_not_hard_deleted!
      if hard_deleted?
        raise CannotUpdateHardDeletedRecordError,
              "Cannot make further updates to this record because it has been hard deleted"
      end
    end

    def write_attribute_without_callbacks(attribute_name, value)
      without_callbacks do
        write_attribute(attribute_name, value)
      end
    end

    def write_attribute(attribute_name, value)
      verify_transaction_is_open!
      verify_not_hard_deleted!

      with_changed_attribute_callbacks(attribute_name) do
        load_if_necessary!(attribute_name)

        attribute_name = attribute_name.to_sym

        if attribute_name == primary_key_attribute
          if value.nil?
            # :nocov:
            raise "Primary key cannot be set to a blank value"
            # :nocov:
          end

          if value.is_a?(::String) && value.empty?
            # :nocov:
            raise "Primary key cannot be set to a blank value"
            # :nocov:
          end

          if value.is_a?(::Symbol) && value.to_s.empty?
            # :nocov:
            raise "Primary key cannot be set to a blank value"
            # :nocov:
          end

          write_attribute!(attribute_name, value)
        else
          attribute_name = attribute_name.to_sym
          outcome = cast_attribute(attribute_name, value)
          attributes[attribute_name] = outcome.success? ? outcome.result : value
        end
      end
    end

    def write_attribute_without_callbacks!(attribute_name, value)
      without_callbacks do
        write_attribute!(attribute_name, value)
      end
    end

    def write_attribute!(attribute_name, value)
      verify_transaction_is_open!
      verify_not_hard_deleted!

      with_changed_attribute_callbacks(attribute_name) do
        load_if_necessary!(attribute_name)

        attribute_name = attribute_name.to_sym

        if attribute_name == primary_key_attribute && primary_key
          outcome = cast_attribute(attribute_name, value)

          if outcome.success?
            value = outcome.result
          end

          if value != primary_key
            raise UnexpectedPrimaryKeyChangeError,
                  "Primary key already set to #{primary_key}. Can't change to #{value}. " \
                  "Use attributes[:#{attribute_name}] = #{value.inspect} " \
                  "instead if you really want to change the primary key."
          end
        end

        attribute_name = attribute_name.to_sym
        attributes[attribute_name] = cast_attribute!(attribute_name, value)
      end
    end

    def write_attributes_without_callbacks(attributes)
      without_callbacks do
        write_attributes(attributes)
      end
    end

    def write_attributes(attributes)
      verify_transaction_is_open!
      verify_not_hard_deleted!

      with_changed_attribute_callbacks(attributes.keys) do
        load_if_necessary!(attributes)

        attributes.each_pair do |attribute_name, value|
          write_attribute_without_callbacks(attribute_name, value)
        end
      end
    end

    def with_changed_attribute_callbacks(attribute_names)
      # TODO: clean up methods to use this flag instead of calling each other
      if @callbacks_disabled
        yield
        return
      end

      attribute_names = Util.array(attribute_names)

      old_is_dirty = dirty? # TODO: don't bother with this check unless there are relevant callbacks
      old_is_valid = valid? # TODO: don't bother with this check unless there are relevant callbacks

      old_values = attribute_names.map { |attribute_name| read_attribute(attribute_name) }

      yield

      new_values = attribute_names.map { |attribute_name| read_attribute(attribute_name) }

      attribute_changed = false

      old_values.each.with_index do |old_value, index|
        new_value = new_values[index]

        if new_value != old_value
          attribute_changed = true
          fire(:attribute_changed, attribute_name: attribute_names[index], old_value:, new_value:)
        end
      end

      if attribute_changed
        new_is_dirty = dirty?

        if old_is_dirty != new_is_dirty
          old_is_dirty ? fire(:undirtied) : fire(:dirtied)
        end

        new_is_valid = valid?

        if old_is_valid != new_is_valid
          # TODO: don't bother with this check unless there are relevant callbacks
          new_is_valid ? fire(:uninvalidated) : fire(:invalidated)
        end
      end
    end

    def successfully_loaded(attributes)
      already_loaded = loaded?

      write_attributes_without_callbacks(attributes)
      self.is_loaded = true

      save_persisted_attributes

      unless already_loaded
        fire(:loaded)
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

    def inspect
      "<#{entity_name}:#{primary_key}>"
    end
  end
end
