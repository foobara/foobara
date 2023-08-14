require "foobara/types/atom_type"

module Foobara
  module Types
    module BuiltinTypes
      # TODO: create a structured type superclass?
      class TypedAttributesType < AttributesType
        attr_accessor :attributes_processor

        def initialize(*args, children_types: {}, **opts)
          super(*args, **opts)
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
