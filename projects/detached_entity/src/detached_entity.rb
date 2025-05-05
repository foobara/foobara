module Foobara
  class DetachedEntity < Model
    include Concerns::Attributes
    include Concerns::Persistence
    include Concerns::Equality
    include Concerns::Associations
    include Concerns::PrimaryKey
    include Concerns::Reflection
    include Concerns::Types
    include Concerns::Aliases
    include Concerns::Serialize
    include Concerns::Initialization
  end
end
