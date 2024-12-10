module Foobara
  class Command
    include TruncatedInspect

    include Concerns::Description
    include Concerns::Namespace

    include Concerns::InputsType
    include Concerns::ErrorsType
    include Concerns::ResultType

    include Concerns::Inputs
    include Concerns::Errors
    include Concerns::Result

    include Concerns::Runtime
    include Concerns::Callbacks
    include Concerns::StateMachine
    include Concerns::Transactions
    include Concerns::Entities
    include Concerns::Subcommands
    include Concerns::DomainMappers
    include Concerns::Reflection

    # TODO: this feels like a hack and shouldn't be necessary. Let's try to fix Concern class inheritance, instead.
    self.subclass_defined_callbacks ||= Foobara::Callback::Registry::SingleAction.new

    attr_reader :raw_inputs

    def initialize(inputs = {})
      @raw_inputs = inputs
      super()
    end
  end

  Command.after_subclass_defined do |subclass|
    Command.all << subclass
    subclass.define_command_named_function
  end
end
