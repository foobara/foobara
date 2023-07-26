module Foobara
  class SchemaError < Error
    attr_accessor :path

    def initialize(path:, **args)
      self.path = path
      super(**args)
    end

    def eql?(other)
      super && other.is_a?(AttributeError) && attribute_name == other.attribute_name && path == other.path
    end

    def to_h
      super.merge(attribute_name:, path:)
    end
  end
end
