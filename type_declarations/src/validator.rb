module Foobara
  module TypeDeclarations
    class Validator < Value::Validator
      include WithRegistries
    end
  end
end
