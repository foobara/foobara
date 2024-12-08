module Foobara
  class Entity < DetachedEntity
    include Concerns::Callbacks
    include Concerns::Transactions
    include Concerns::Queries
    include Concerns::Mutations
    include Concerns::Attributes
    include Concerns::Persistence
    include Concerns::Initialization
    include Concerns::AttributeHelpers

    class << self
      prepend NewPrepend
    end
  end
end
