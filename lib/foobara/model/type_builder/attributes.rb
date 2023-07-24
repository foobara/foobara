module Foobara
  class Model
    class TypeBuilder
      class Attributes < TypeBuilder
        # Why is this now happening in multiple places??
        # TODO: fix this
        def direct_cast_ruby_classes
          []
        end
      end
    end
  end
end
