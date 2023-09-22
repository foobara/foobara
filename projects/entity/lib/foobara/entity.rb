require "date"
require "time"
require "bigdecimal"

Foobara.load_project(__dir__)

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
        TypeDeclarations.register_type_declaration(TypeDeclarations::Handlers::ExtendEntityTypeDeclaration.new)
      end

      def reset_all
        Util.constant_values(self, extends: Foobara::Entity).each do |dynamic_model|
          remove_const(Util.non_full_name(dynamic_model))
        end

        install!
      end
    end

    install!
  end
end
