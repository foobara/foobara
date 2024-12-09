module Foobara
  module BuiltinTypes
    module Entity
      module Casters
        # TODO: We need a way of disabling/enabling this and it should probably be disabled by default.
        class Hash < DetachedEntity::Casters::Hash
          def build_method(attributes)
            outcome = entity_class.attributes_type.process_value(attributes)

            outcome.result

            if outcome.success?
              :create
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
