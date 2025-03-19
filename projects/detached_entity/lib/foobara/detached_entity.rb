module Foobara
  class DetachedEntity < Model
    abstract

    class << self
      # Need to override this otherwise we install Model twice
      def install!
        handler = TypeDeclarations::Handlers::ExtendDetachedEntityTypeDeclaration.new
        TypeDeclarations.register_type_declaration(handler)

        TypeDeclarations.register_sensitive_type_remover(SensitiveTypeRemovers::DetachedEntity.new(handler))

        model = Namespace.global.foobara_lookup_type!(:model)
        BuiltinTypes.build_and_register!(:detached_entity, model, nil)
      end

      def reset_all
        install!
      end
    end
  end
end
