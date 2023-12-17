module Foobara
  module Manifest
    class Command < BaseManifest
      self.category_symbol = :command

      def command_manifest
        relevant_manifest
      end

      def command_name
        scoped_short_name
      end

      def inputs_type
        Attributes.new(root_manifest, [*path, :inputs_type])
      end

      def result_type
        TypeDeclaration.new(root_manifest, [*path, :result_type])
      end

      def error_types
        super.keys.to_h do |key|
          [key, PossibleError.new(root_manifest, [*path, :error_types, key])]
        end
      end

      def types_depended_on
        @types_depended_on ||= self[:types_depended_on].map do |type_reference|
          Type.new(root_manifest, [:type, type_reference])
        end
      end

      def inputs_types_depended_on
        @inputs_types_depended_on ||= self[:inputs_types_depended_on].map do |type_reference|
          Type.new(root_manifest, [:type, type_reference])
        end
      end

      def result_types_depended_on
        @result_types_depended_on ||= self[:result_types_depended_on].to_set do |type_reference|
          Type.new(root_manifest, [:type, type_reference])
        end
      end

      def errors_types_depended_on
        @errors_types_depended_on ||= self[:errors_types_depended_on].to_set do |type_reference|
          Type.new(root_manifest, [:type, type_reference])
        end
      end
    end
  end
end
