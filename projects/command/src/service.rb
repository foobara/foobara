module Foobara
  # We distinguish between "Foobara Command" and the "command pattern".
  #
  # A "Foobara Command" encapsulates a high-level business operation and serves as the public interface to its domain.
  #
  # The "command pattern" encapsulates an operation behind an interface that supports .new(inputs), #run which returns
  # an outcome which implements #success?, #result, and #errors.
  #
  # All "Foobara Command"s implement the "command pattern" but not all implementations of the "command pattern"
  # are "Foobara Command"s.  An example is DomainMappers.  They happen to use the "command pattern" since it is a good
  # fit but has nothing to do with a public interface high-level business operation encapsulation like a
  # "Foobara Command" does.
  module CommandPatternImplementation
    include Concern

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
  end
end
