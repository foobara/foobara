module Foobara
  class DetachedEntity < Model
    include Concerns::Associations
    include Concerns::PrimaryKey
    include Concerns::Reflection
    include Concerns::Types
  end
end
