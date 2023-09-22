module Foobara
  module TypeDeclarations
    class << self
      attr_accessor :validate_error_context_enabled

      def validate_error_context_enabled?
        validate_error_context_enabled
      end

      def with_validate_error_context_disabled
        old_enabled = validate_error_context_enabled

        begin
          self.validate_error_context_enabled = false
          yield
        ensure
          self.validate_error_context_enabled = old_enabled
        end
      end
    end

    self.validate_error_context_enabled = true

    module ErrorExtension
      include Concern
      include WithRegistries

      module ClassMethods
        def context_type
          type_for_declaration(context_type_declaration)
        end

        def context_type_declaration
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end
      end

      def initialize(...)
        super

        validate_context!
      end

      def validate_context!
        if TypeDeclarations.validate_error_context_enabled?
          # TODO: we need to wrap this in a new error here to communicate what's going on a bit better
          context_type.process_value!(context)
        end
      end

      foobara_delegate :context_type, :context_type_declaration, to: :class
    end
  end
end
