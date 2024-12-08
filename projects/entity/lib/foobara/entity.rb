module Foobara
  # TODO: I think we should have a configuration that indicates if created records can have primary keys past to them
  # or not. That is, do primary keys get issued by the database upon insertion? Or are they generated externally
  # and passed in? Would be nice to have programmatic clarification via explicit configuration.
  class Entity < DetachedEntity
    abstract

    class << self
      def install!
        TypeDeclarations.register_type_declaration(TypeDeclarations::Handlers::ExtendEntityTypeDeclaration.new)

        model = Namespace.global.foobara_lookup_type!(:model)
        BuiltinTypes.build_and_register!(:entity, model, nil)
      end

      def reset_all
        Entity::Concerns::Callbacks.reset_all

        install!
      end
    end
  end
end
