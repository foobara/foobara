module Foobara
  class DetachedEntity < Model
    module SensitiveValueRemovers
      class DetachedEntity < Model::SensitiveValueRemovers::Model
      end
    end
  end
end
