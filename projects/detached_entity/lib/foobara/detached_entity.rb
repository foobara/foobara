module Foobara
  class DetachedEntity < Model
    abstract

    class << self
      # Need to override this otherwise we install Model twice
      def install!
        TypeDeclarations.register_type_declaration(TypeDeclarations::Handlers::ExtendDetachedEntityTypeDeclaration.new)

        model = Namespace.global.foobara_lookup_type!(:model)
        BuiltinTypes.build_and_register!(:detached_entity, model, nil)
      end

      def reset_all
        install!
      end
    end
  end
end
