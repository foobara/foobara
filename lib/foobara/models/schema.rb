require "foobara/models"

module Foobara
  module Models
    class Schema
      attr_accessor :raw_schema, :strict_schema, :errors, :has_been_validated

      def initialize(raw_schema)
        self.errors = []
        self.raw_schema = raw_schema
      end

      def valid?
        validate unless validated?

        errors.empty?
      end

      def type
        validate unless validated?

        strict_schema[:type]
      end

      def desugarize
        self.strict_schema = case raw_schema
                             when Symbol
                               { type: raw_schema }
                             else
                               raw_schema
                             end
      end

      def validate
        self.has_been_validated = true

        desugarize

        return unless valid?

        unless Models.types.key?(type)
          errors << "Unknown type: #{type}"
        end
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
