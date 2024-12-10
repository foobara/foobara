module Foobara
  # TODO: would be nice to inherit from something other than Command. Can we hoist a bunch of common behavior up
  # out of Command into some other class maybe called Service or Runnable or something?
  class DomainMapper < Foobara::Command
    class << self
      def map(value)
        new(from: value).run
      end

      def map!(value)
        new(from: value).run!
      end

      def from(...)
        result(...)
      end

      # A bit hacky because Command only supports attributes inputs at the moment, ugg.
      def to(...)
        from_type = domain.type_from_declaration(...)

        inputs do
          from from_type, :required
        end
      end

      def from_type
        inputs_type.element_types[:from]
      end

      def to_type
        result_type
      end

      def applicable?(from_value, to_value)
        matches?(from_type, from_value) && matches?(to_type, to_value)
      end

      def matches?(type_indicator, value)
        return true if type_indicator.nil? || value.nil? || type_indicator == value

        type = object_to_type(type_indicator)

        return true if type.nil? || type == value
        return true if type.applicable?(value) && type.process_value(value).success?

        if value.is_a?(Types::Type)
          if !value.registered? && !type.registered?
            value.declaration_data == type.declaration_data
          end
        else
          value_type = object_to_type(value)

          if value_type
            matches?(type, value_type)
          end
        end
      end

      # TODO: should this be somewhere more general-purpose?
      def object_to_type(object)
        if object
          if object.is_a?(::Class)
            if object < Foobara::Model
              object.model_type
            elsif object < Foobara::Command
              object.inputs_type
            else
              domain.foobara_type_from_declaration(object)
            end
          else
            case object
            when Types::Type
              object
            when ::Symbol
              domain.foobara_lookup_type!(object)
            end
          end
        end
      end
    end

    def from_type
      self.class.from_type
    end

    def to_type
      self.class.to_type
    end

    def execute
      map
    end

    def map
      # :nocov:
      raise "subclass responsibility"
      # :nocov:
    end
  end
end
