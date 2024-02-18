module Foobara
  class Command
    class << self
      def install!
        Namespace.global.foobara_add_category_for_subclass_of(:command, self)
      end
    end
  end
end
