module Foobara
  # TODO: this is the wrong namespace! fix this
  class AttributeError < Error
    attr_accessor :attribute_name, :path

    def initialize(attribute_name:, path:, **data)
      super(**data)

      self.path = path
      self.attribute_name = attribute_name
    end

    def eql?(other)
      super && other.is_a?(AttributeError) && attribute_name == other.attribute_name
    end

    def to_h
      super.merge(attribute_name:, path:)
    end
  end
end
