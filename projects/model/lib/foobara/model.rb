require "date"
require "time"
require "bigdecimal"

module Foobara
  class Model
    class << self
      def install!
        TypeDeclarations.register_type_declaration(TypeDeclarations::Handlers::ExtendModelTypeDeclaration.new)
        TypeDeclarations.register_type_declaration(TypeDeclarations::Handlers::ExtendRegisteredModelTypeDeclaration.new)

        atomic_duck = TypeDeclarations::Namespace.type_for_symbol(:atomic_duck)
        BuiltinTypes.build_and_register!(:model, atomic_duck, nil)
        # address = build_and_register!(:address, model)
        # us_address = build_and_register!(:us_address, model)
      end

      def reset_all
        Foobara::Util.constant_values(self, extends: Foobara::Model).each do |dynamic_model|
          remove_const(Util.non_full_name(dynamic_model))
        end

        install!
      end
    end
  end
end
