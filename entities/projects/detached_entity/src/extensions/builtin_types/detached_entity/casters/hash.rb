module Foobara
  module BuiltinTypes
    module DetachedEntity
      module Casters
        class Hash < BuiltinTypes::Model::Casters::Hash
          class << self
            def requires_parent_declaration_data?
              true
            end
          end

          def expected_type_symbol
            :detached_entity
          end

          def entity_class
            model_class
          end
        end
      end
    end
  end
end
