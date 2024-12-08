module Foobara
  class DetachedEntity < Model
    include Concerns::PrimaryKey
    include Concerns::Reflection
  end
end
