module Foobara
  class DetachedEntity < Model
    abstract

    class << self
      # Need to override this otherwise we install Model twice
      def install!
        model = Namespace.global.foobara_lookup_type!(:model)
        BuiltinTypes.build_and_register!(:detached_entity, model, nil)
      end
    end
  end
end
