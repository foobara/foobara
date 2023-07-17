module Foobara
  class Command
    include Concerns::InputSchema
    include Concerns::ErrorSchema
    include Concerns::ResultSchema
    include Concerns::Runtime
    include Concerns::Callbacks

    attr_reader :raw_inputs

    def initialize(inputs)
      @raw_inputs = inputs
      super()
    end

    def state_machine
      # It makes me nervous to pass self around. Seems like a design smell.
      @state_machine ||= StateMachine.new(owner: self)
    end
  end
end
