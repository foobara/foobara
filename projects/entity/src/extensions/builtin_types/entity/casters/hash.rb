module Foobara
  module BuiltinTypes
    module Entity
      module Casters
        # TODO: We need a way of disabling/enabling this and it should probably be disabled by default.
        class Hash < Attributes::Casters::Hash
          class << self
            def requires_parent_declaration_data?
              true
            end
          end

          def cast(attributes)
            symbolized_attributes = super

            outcome = entity_class.attributes_type.process_value(symbolized_attributes)

            if outcome.success?
              entity_class.create(symbolized_attributes)
            else
              # we build an instance so that it can fail a validator later. But we already know we don't want to
              # persist this thing. So use build instead of create.
              entity_class.build(outcome.result)
            end
          end

          def entity_class
            type = parent_declaration_data[:type]

            if type == :entity
              Object.const_get(parent_declaration_data[:model_class])
            else
              Foobara::Namespace.current.foobara_lookup_type!(type).target_class
            end
          end
        end
      end
    end
  end
end
