require "date"
require "time"
require "bigdecimal"

module Foobara
  # TODO: I think we should have a configuration that indicates if created records can have primary keys past to them
  # or not. That is, do primary keys get issued by the database upon insertion? Or are they generated externally
  # and passed in? Would be nice to have programmatic clarification via explicit configuration.
  class Entity < Model
    abstract

    class << self
      def install!
        model = TypeDeclarations::Namespace.type_for_symbol(:model)

        BuiltinTypes.build_and_register!(:entity, model, nil)

        TypeDeclarations.register_type_declaration(TypeDeclarations::Handlers::ExtendEntityTypeDeclaration.new)
      end

      def reset_all
        Entity::Concerns::Callbacks.reset_all

        Util.constant_values(self, extends: Foobara::Entity).each do |dynamic_model|
          remove_const(Util.non_full_name(dynamic_model))
        end

        install!
      end
    end
  end
end
