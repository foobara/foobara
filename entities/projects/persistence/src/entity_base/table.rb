module Foobara
  module Persistence
    class EntityBase
      # TODO: this class seems useless and confusing since we have two other Table classes
      class Table
        attr_accessor :table_name, :entity_base

        def initialize(table_name, entity_base)
          self.entity_base = entity_base
          self.table_name = table_name
        end
      end
    end
  end
end
