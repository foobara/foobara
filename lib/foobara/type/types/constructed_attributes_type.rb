require "foobara/type/types/constructed_atom_type"

module Foobara
  class Type < Value::Processor
    module Types
      class ConstructedAttributesType < ConstructedAtomType
        attr_accessor :attributes_processor

        def initialize(children_types: {}, **opts)
          super(**opts)
          self.attributes_processor = AttributesProcessor.new(children_types)
        end

        delegate :children_types, to: :attributes_processor

        def processors
          [*super, attributes_processor]
        end
      end
    end
  end
end
