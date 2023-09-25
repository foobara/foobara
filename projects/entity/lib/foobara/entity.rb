require "date"
require "time"
require "bigdecimal"

module Foobara
  class Entity < Model
    class << self
      def install!
        model = TypeDeclarations::Namespace.type_for_symbol(:model)

        BuiltinTypes.build_and_register!(:entity, model, nil)

        TypeDeclarations.register_type_declaration(TypeDeclarations::Handlers::ExtendEntityTypeDeclaration.new)
      end

      def reset_all
        # wtf
        # Entity::Concerns::Callbacks.reset_all

        Util.constant_values(self, extends: Foobara::Entity).each do |dynamic_model|
          remove_const(Util.non_full_name(dynamic_model))
        end

        install!
      end
    end
  end
end
