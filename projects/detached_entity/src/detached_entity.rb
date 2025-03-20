module Foobara
  class DetachedEntity < Model
    include Concerns::Equality
    include Concerns::Associations
    include Concerns::PrimaryKey
    include Concerns::Reflection
    include Concerns::Types
    include Concerns::Aliases
    include Concerns::Serialize
  end
end
