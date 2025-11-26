module Foobara
  class Model
    module Concerns
      module Aliases
        include Concern

        module ClassMethods
          def model_name(...)
            foobara_model_name(...)
          end

          def delegates(...)
            foobara_delegates(...)
          end

          def private_attribute_names
            foobara_private_attribute_names
          end
        end
      end
    end
  end
end
