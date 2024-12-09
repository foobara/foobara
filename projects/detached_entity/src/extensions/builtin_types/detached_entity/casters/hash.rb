module Foobara
  module BuiltinTypes
    module DetachedEntity
      module Casters
        class Hash < Attributes::Casters::Hash
          class << self
            def requires_parent_declaration_data?
              true
            end
          end

          def cast(attributes)
            symbolized_attributes = super

            entity_class.send(build_method(symbolized_attributes), symbolized_attributes)
          end

          def build_method(_symbolized_attributes)
            :new
          end

          def entity_class
            type = parent_declaration_data[:type]

            if type == expected_type_symbol
              Object.const_get(parent_declaration_data[:model_class])
            else
              Foobara::Namespace.current.foobara_lookup_type!(type).target_class
            end
          end

          def expected_type_symbol
            :detached_entity
          end
        end
      end
    end
  end
end
