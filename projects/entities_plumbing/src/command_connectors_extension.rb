module Foobara
  module EntitiesPlumbing
    module CommandConnectorsExtension
      module ClassMethods
        def to_auth_user_mapper(object)
          if object.is_a?(::Class) && object < Foobara::Entity
            TypeDeclarations::TypedTransformer.subclass(to: object) do |authenticated_user|
              object.that_owns(authenticated_user)
            end.instance
          else
            super
          end
        end
      end
    end
  end
end
