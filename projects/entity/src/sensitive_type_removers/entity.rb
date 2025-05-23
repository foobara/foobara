module Foobara
  class Entity < DetachedEntity
    module SensitiveTypeRemovers
      class Entity < DetachedEntity::SensitiveTypeRemovers::DetachedEntity
        def transform(strict_type_declaration)
          new_type_declaration = super

          if strict_type_declaration != new_type_declaration
            if new_type_declaration[:type] == :entity
              new_type_declaration[:type] = :detached_entity

              if new_type_declaration[:model_base_class] == "Foobara::Entity"
                new_type_declaration[:model_base_class] = "Foobara::DetachedEntity"
              end
            end
          end

          new_type_declaration
        end
      end
    end
  end
end
