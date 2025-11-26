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

    include CommandPatternImplementation::Concerns::Description
    include CommandPatternImplementation::Concerns::Namespace

    include CommandPatternImplementation::Concerns::InputsType
    include CommandPatternImplementation::Concerns::ErrorsType
    include CommandPatternImplementation::Concerns::ResultType

    include CommandPatternImplementation::Concerns::Inputs
    include CommandPatternImplementation::Concerns::Errors
    include CommandPatternImplementation::Concerns::Result

    include CommandPatternImplementation::Concerns::Runtime
    include CommandPatternImplementation::Concerns::Callbacks
    include CommandPatternImplementation::Concerns::StateMachine
    include CommandPatternImplementation::Concerns::Transactions
    include CommandPatternImplementation::Concerns::Entities
    include CommandPatternImplementation::Concerns::Subcommands
    include CommandPatternImplementation::Concerns::DomainMappers
    include CommandPatternImplementation::Concerns::Reflection
  end
end
