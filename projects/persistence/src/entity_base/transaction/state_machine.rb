module Foobara
  module Persistence
    class EntityBase
      class Transaction
        class StateMachine < Foobara::StateMachine
          # TODO: make these outer braces optional somehow
          set_transition_map({
                               unopened: {
                                 open: :open,
                                 open_nested: :open,
                                 close: :closed
                               },
                               open: {
                                 # TODO: maybe call this something involving "checkpoint"?
                                 flush: :open,
                                 revert: :open,
                                 close: :closed,
                                 # TODO: should we have intermediate states to quickly get out of the open state?
                                 rollback: :closed,
                                 commit: :closed,
                                 error: :closed,
                                 commit_nested: :closed,
                                 rollback_nested: :closed
                               }
                             })
        end
      end
    end
  end
end
