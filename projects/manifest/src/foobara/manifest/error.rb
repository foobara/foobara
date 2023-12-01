module Foobara
  module Manifest
    class Error < BaseManifest
      def error_manifest
        relevant_manifest
      end

      def symbol
        super.to_sym
      end

      def global?
        global_symbols.include?(symbol.to_sym)
      end

      def global_symbols
        %i[
          cannot_cast
          missing_required_attribute
          unexpected_attributes
        ]
      end

      def organization_name
        if global?
          "global_organization"
        else
          path[1].to_s
        end
      end

      def domain_name
        if global?
          "global_domain"
        else
          path[3].to_s
        end
      end

      # oops, shadowed the convenience method
      def _path
        method_missing(:path)
      end
    end
  end
end
