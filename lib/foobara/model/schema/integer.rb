module Foobara
  class Model
    class Schema
      class Integer < Schema
      end

      Integer.autoregister_processors
    end
  end
end
