module Foobara
  class Model
    module Schemas
      class Integer < Schema
      end

      Integer.autoregister_processors
    end
  end
end
