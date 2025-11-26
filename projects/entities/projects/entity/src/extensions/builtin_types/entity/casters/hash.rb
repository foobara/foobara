module Foobara
  module BuiltinTypes
    module Entity
      module Casters
        # TODO: We need a way of disabling/enabling this and it should probably be disabled by default.
        class Hash < DetachedEntity::Casters::Hash
          def build_method(attributes)
            outcome = entity_class.attributes_type.process_value(attributes)

            if outcome.success?
              cast_attributes = outcome.result

              primary_key_value = cast_attributes[entity_class.primary_key_attribute]

              if primary_key_value
                # TODO: we need a way to specify if an entity requires a primary key upon creation (guid style)
                # or not (autoincrement assigned by data store style.)
                # This code path was added because of following use-case: command returns attributes
                # of an existing record for a result_type of the entity class. We really just want to wrap
                # it in that class but we don't want to create the thing.
                if entity_class.exists?(primary_key_value)
                  :build
                else
                  :create
                end
              else
                :create
              end
            else
              # we build an instance so that it can fail a validator later. But we already know we don't want to
              # persist this thing. So use build instead of create.
              :build
            end
          end

          def expected_type_symbol
            :entity
          end
        end
      end
    end
  end
end
