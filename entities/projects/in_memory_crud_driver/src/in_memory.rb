module Foobara
  module Persistence
    module CrudDrivers
      class InMemory < InMemoryMinimal
        class Table < InMemoryMinimal::Table
        end
      end
    end
  end
end
