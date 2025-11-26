module Foobara
  class DetachedEntity < Model
    module SensitiveTypeRemovers
      class DetachedEntity < Model::SensitiveTypeRemovers::Model
      end
    end
  end
end
