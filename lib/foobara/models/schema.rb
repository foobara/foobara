require "foobara/models"

module Foobara
  module Models
    class Schema
      attr_accessor :raw_schema, :strict_schema, :errors, :has_been_validated

      def initialize(raw_schema)
        self.errors = []
        self.raw_schema = raw_schema

        desugarize!
      end

      def valid?
        validate unless validated?

        errors.empty?
      end

      def type
        strict_schema[:type]
      end

      def desugarize!
        # TODO: need a real implementation
        self.strict_schema = raw_schema
      end

      def validate
        unless Models.types.key?(type)
          errors << "Unknown type: #{type}"
        end

        self.has_been_validated = true
      end

      def apply(_object)
        raise "not yet implemented"
      end

      def validated?
        has_been_validated
      end
    end
  end
end
