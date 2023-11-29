module Foobara
  class Manifest
    class BaseManifest
      attr_accessor :root_manifest, :path

      def initialize(root_manifest, path)
        self.root_manifest = root_manifest
        self.path = path
      end

      def relevant_manifest
        @relevant_manifest ||= Foobara::DataPath.values_at(path, root_manifest).first
      end

      def method_missing(method_name, *, &)
        if relevant_manifest.key?(method_name.to_sym)
          relevant_manifest[method_name.to_sym]
        elsif relevant_manifest.key?(method_name.to_s)
          relevant_manifest[method_name.to_s]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        relevant_manifest.key?(method_name.to_sym) || relevant_manifest.key?(method_name.to_s) || super
      end

      def inspect
        root_manifest_data = relevant_manifest.to_h do |key, value|
          if value.is_a?(::Array)
            if value.size > 5 || value.any? { |v| _structure?(v) }
              value = "..."
            end
          elsif value.is_a?(::Hash)
            if value.size > 3 || value.keys.any? { |k| !k.is_a?(::Symbol) && !k.is_a?(::String) }
              value = "..."
            elsif value.values.any? { |v| _structure?(v) }
              value = "..."
            end
          end

          if key.is_a?(::String)
            key = key.to_sym
          end

          [key, value]
        end

        "#{path.inspect}: #{root_manifest_data.inspect}"
      end

      def _structure?(object)
        object.is_a?(::Hash) || object.is_a?(::Array)
      end
    end
  end
end
