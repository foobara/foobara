module Foobara
  class Model
    module Concerns
      module Aliases
        include Concern

        module ClassMethods
          def model_name(...)
            foobara_model_name(...)
          end
        end
      end
    end
  end
end
