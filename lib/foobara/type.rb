require "active_support/core_ext/array/conversions"
require "singleton"

Foobara::Util.require_directory("#{__dir__}/type")

module Foobara
  class Type < Value::Processor
    class << self
      attr_accessor :root_type
    end

    attr_accessor :base_type

    def initialize(declaration_data = true, base_type: Type.root_type)
      super(declaration_data)
      self.base_type = base_type
    end

    def call(...)
      process(...)
    end

    # TODO: also should have abstract method for error classes...
    def process(_value, _path = [])
      raise "subclass responsibility"
    end

    def process!(value)
      outcome = process(value)

      if outcome.success?
        outcome.result
      else
        outcome.raise!
      end
    end
  end
end
