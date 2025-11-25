require "date"
require "time"
require "bigdecimal"

module Foobara
  class Model
    class << self
      def install!
        model_handler = TypeDeclarations::Handlers::ExtendModelTypeDeclaration.new
        TypeDeclarations.register_type_declaration(model_handler)
        extended_model_handler = TypeDeclarations::Handlers::ExtendRegisteredModelTypeDeclaration.new
        TypeDeclarations.register_type_declaration(extended_model_handler)

        TypeDeclarations.register_sensitive_type_remover(SensitiveTypeRemovers::Model.new(model_handler))
        TypeDeclarations.register_sensitive_value_remover(model_handler, SensitiveValueRemovers::Model)
        TypeDeclarations.register_sensitive_type_remover(
          SensitiveTypeRemovers::ExtendedModel.new(extended_model_handler)
        )
        # TypeDeclarations.register_sensitive_value_remover(
        #   extended_model_handler,
        #   SensitiveValueRemovers::ExtendedModel
        # )

        atomic_duck = Namespace.global.foobara_lookup_type!(:atomic_duck)
        BuiltinTypes.build_and_register!(:model, atomic_duck, nil)
        # address = build_and_register!(:address, model)
        # us_address = build_and_register!(:us_address, model)
      end

      def reset_all
        Foobara.raise_if_production!("reset_all")
        install!
      end
    end
  end
end
