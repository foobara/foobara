module Foobara
  module TypeDeclarations
    class Transformer < Value::Transformer
      include WithRegistries
    end
  end
end
