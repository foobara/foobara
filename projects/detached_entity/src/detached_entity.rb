module Foobara
  class DetachedEntity < Model
    include Concerns::Equality
    include Concerns::Associations
    include Concerns::PrimaryKey
    include Concerns::Reflection
    include Concerns::Types

    class << self
      def allowed_subclass_opts
        [:primary_key, *super]
      end
    end
  end
end
