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
    end
  end
end
