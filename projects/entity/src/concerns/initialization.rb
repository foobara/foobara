module Foobara
  class Entity < Model
    module Concerns
      module Initialization
        include Concern

        module ClassMethods
          def build(attributes_or_id)
            new(attributes_or_id, outside_transaction: true)
          end
        end

        def build(attributes = {})
          write_attributes_without_callbacks(attributes)
        end
      end
    end
  end
end
