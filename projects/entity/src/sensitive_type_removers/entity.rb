module Foobara
  class Entity < DetachedEntity
    module SensitiveTypeRemovers
      class Entity < DetachedEntity::SensitiveTypeRemovers::DetachedEntity
        def transform(strict_type_declaration)
          new_type_declaration = super

          if strict_type_declaration != new_type_declaration
            if new_type_declaration[:type] == :entity
              if Namespace.current.foobara_root_namespace == Namespace.global.foobara_root_namespace
                # Nervous about creating two entities with the same name in the same namespace
                # So going to create a detached entity instead
                new_type_declaration[:type] = :detached_entity

                if new_type_declaration[:model_base_class] == "Foobara::Entity"
                  new_type_declaration[:model_base_class] = "Foobara::DetachedEntity"
                end
              end
            end
          end

          new_type_declaration
        end
      end
    end
  end
end
