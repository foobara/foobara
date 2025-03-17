module Foobara
  module Manifest
    class Error < BaseManifest
      self.category_symbol = :error

      def error_manifest
        relevant_manifest
      end

      def symbol
        super.to_sym
      end

      def error_name
        scoped_name
      end

      def short_error_name
        scoped_short_name
      end

      def full_error_name
        scoped_full_name
      end

      def abstract
        self[:abstract]
      end

      def types_depended_on
        @types_depended_on ||= self[:types_depended_on].map do |type_reference|
          Type.new(root_manifest, [:type, type_reference])
        end
      end
    end
  end
end
