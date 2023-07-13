module Foobara
  class Command
    include StateMachine
    include Schemas
    include Runtime
  end
end
