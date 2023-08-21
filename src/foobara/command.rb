module Foobara
  class Command
    include Concerns::Namespace

    include Concerns::InputType
    include Concerns::ErrorType
    include Concerns::ResultType

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
