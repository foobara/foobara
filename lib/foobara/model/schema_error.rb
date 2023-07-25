module Foobara
  class SchemaError < Error
    attr_accessor :path

    def initialize(path:, **args)
      self.path = path
      super(**args)
    end
  end
end
