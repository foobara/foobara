module Foobara
  module Manifest
    # TODO: override new to return Entity when it's an entity
    class Type < BaseManifest
      self.category_symbol = :type

      class << self
        def new(root_manifest, path)
          type = super(root_manifest, path)

          if self == Type
            if type.entity?
              Entity.new(type.root_manifest, type.path)
            elsif type.model?
              Model.new(type.root_manifest, type.path)
            end
          else
            type
          end
        end
      end

      def type_manifest
        relevant_manifest
      end

      def entity?
        # TODO: test this with inheritance
        binding.pry
        base_type&.to_sym == :entity
      end

      def model?
        binding.pry
        base_type&.to_sym == :model
      end

      def target_class
        if target_classes.size != 1
          # :nocov:
          raise "Can only use #target_class for types with one target class but #{name} has #{target_classes.size}"
          # :nocov:
        end

        target_classes.first
      end

      def types_depended_on
        @types_depended_on ||= self[:types_depended_on].map do |type_reference|
          Type.new(root_manifest, [:type, type_reference])
        end
      end
    end
  end
end
