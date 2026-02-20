module Foobara
  # TODO: we should probably include CommandPatternImplementation instead of inheriting from Foobara::Command
  # but don't want to hunt down plumbing problems that might arise if Query isn't a Command
  class Query < Foobara::Command
    is_query
  end
end
