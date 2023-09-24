require "date"
require "time"
require "bigdecimal"

module Foobara
  class Entity < Model
    class << self
      def install!
        atomic_duck = TypeDeclarations::Namespace.type_for_symbol(:atomic_duck)
        model = BuiltinTypes.build_and_register!(:model, atomic_duck, nil)
        BuiltinTypes.build_and_register!(:entity, model, nil)
        # address = build_and_register!(:address, model)
        # us_address = build_and_register!(:us_address, model)

        TypeDeclarations.register_type_declaration(TypeDeclarations::Handlers::ExtendModelTypeDeclaration.new)
      end

      def reset_all
        install!
      end
    end
  end
end
