module Foobara
  class DetachedEntity < Model
    module Concerns
      # Too simple to include Concern
      module Persistence
        attr_accessor :is_loaded

        def loaded?
          is_loaded
        end
      end
    end
  end
end
