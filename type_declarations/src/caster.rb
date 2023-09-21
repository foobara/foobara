module Foobara
  module TypeDeclarations
    class Caster < Value::Caster
      include WithRegistries
    end
  end
end
