# TODO: move this to its own project
module Foobara
  # This is not a primary/secondary/tertiary concept in Foobara at the moment. Mostly an implementation detail
  # to share behavior between Command and DomainMapper without DomainMapper being a Command.
  # If someday we wish to consider this a primary/secondary/tertiary concept, then
  # it would serve as a type of private command which cannot be called from commands outside of its domain.
  # TODO: Consider making this a mixin called Runnable instead
  class Service
    include TruncatedInspect

    # TODO: move these to Service
    include Command::Concerns::Description
    include Command::Concerns::Namespace

    include Command::Concerns::InputsType
    include Command::Concerns::ErrorsType
    include Command::Concerns::ResultType

    include Command::Concerns::Inputs
    include Command::Concerns::Errors
    include Command::Concerns::Result

    include Command::Concerns::Runtime
    include Command::Concerns::Callbacks
    include Command::Concerns::StateMachine
    include Command::Concerns::Transactions
    include Command::Concerns::Entities
    include Command::Concerns::Subcommands
    include Command::Concerns::DomainMappers
    include Command::Concerns::Reflection

    # TODO: this feels like a hack and shouldn't be necessary. Let's try to fix Concern class inheritance, instead.
    self.subclass_defined_callbacks ||= Foobara::Callback::Registry::SingleAction.new
  end
end
