module Foobara
  module BuiltinTypes
    module Entity
      module Validators
        class AttributesDeclaration < DetachedEntity::Validators::AttributesDeclaration
          def applicable?(record)
            record.created? || record.built?
          end

          def expected_type_symbol
            :entity
          end
        end
      end
    end
  end
end
