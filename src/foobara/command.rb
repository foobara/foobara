module Foobara
  class Command
    include Concerns::InputSchema
    include Concerns::ErrorSchema
    include Concerns::ResultSchema

    include Concerns::Inputs
    include Concerns::Errors
    include Concerns::Result

    include Concerns::Runtime
    include Concerns::Callbacks
    include Concerns::StateMachine
    include Concerns::Subcommands

    attr_reader :raw_inputs

    def initialize(inputs = {})
      @raw_inputs = inputs
      super()
    end
  end
end
