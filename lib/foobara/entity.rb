module Foobara
  # TODO: either make this an abstract base class of ValueModel and Entity or rename it to ValueModel
  # and have Entity inherit from it...
  class Entity < Model
    class UnexpectedPrimaryKeyChangeError < StandardError; end

    class << self
      def reset_all
        Foobara::Util.constant_values(self, extends: Foobara::Entity).each do |dynamic_model|
          remove_const(dynamic_model.name.demodulize)
        end
      end

      def type_declaration(...)
        raise "No primary key set yet" unless primary_key_attribute.present?

        super.merge(type: :entity, primary_key: primary_key_attribute)
      end

      attr_reader :primary_key_attribute

      def primary_key(attribute_name)
        if primary_key_attribute.present?
          # :nocov:
          raise "Primary key already set to #{primary_key_attribute}"
          # :nocov:
        end

        if attribute_name.blank?
          # :nocov:
          raise ArgumentError, "Primary key can't be blank"
          # :nocov:
        end

        @primary_key_attribute = attribute_name.to_sym

        set_model_type
      end

      def set_model_type
        if primary_key_attribute.present?
          super
        end
      end

      def allowed_subclass_opts
        [:primary_key, *super]
      end
    end

    delegate :primary_key_attribute, to: :class

    def ==(other)
      equal?(other) || (self.class == other.class && persisted? && other.persisted? && primary_key == other.primary_key)
    end

    def initialize(*args, validate: false, not_persisted_even_if_primary_key_present: false, **opts)
      attributes = Util.args_and_opts_to_opts(args, opts)

      if attributes.blank?
        if not_persisted_even_if_primary_key_present
          # :nocov:
          raise ArgumentError, "Cannot use not_persisted_even_if_primary_key_present option without attributes"
          # :nocov:
        end

        super({}, validate:)
      elsif attributes.is_a?(::Hash)
        super(attributes, validate:)
        @is_loaded = @is_persisted = primary_key.present? && !not_persisted_even_if_primary_key_present
      else
        if not_persisted_even_if_primary_key_present
          # :nocov:
          raise ArgumentError, "Cannot use not_persisted_even_if_primary_key_present option without attributes"
          # :nocov:
        end

        primary_key = attributes

        if primary_key.blank?
          # :nocov:
          raise ArgumentError, "Primary key cannot be blank"
          # :nocov:
        end

        super({ primary_key_attribute => primary_key }, validate:)

        @is_persisted = true
      end
    end

    def persisted?
      @is_persisted
    end

    def loaded?
      @is_loaded
    end

    def hash
      if primary_key.present?
        primary_key.hash
      else
        super
      end
    end

    def primary_key
      read_attribute(primary_key_attribute)
    end

    def write_attribute(attribute_name, value)
      attribute_name = attribute_name.to_sym

      if attribute_name == primary_key_attribute
        write_attribute!(attribute_name, value)
      else
        super
      end
    end

    def write_attribute!(attribute_name, value)
      attribute_name = attribute_name.to_sym

      if attribute_name == primary_key_attribute && primary_key.present?
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

      super
    end
  end
end
