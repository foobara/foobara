module Foobara
  module Manifest
    class Command < BaseManifest
      def command_manifest
        relevant_manifest
      end

      def inputs_type
        Attributes.new(root_manifest, [*path, :inputs_type])
      end

      def result_type
        TypeDeclaration.new(root_manifest, [*path, :result_type])
      end

      def error_types
        super.keys.to_h do |key|
          [key, Error.new(root_manifest, [*path, :error_types, key])]
        end
      end

      def domain
        Domain.new(root_manifest, path[0..3])
      end
    end
  end
end