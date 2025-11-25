module Foobara
  module BuiltinTypes
    module Entity
      module Validators
        class ModelInstanceIsValid < DetachedEntity::Validators::ModelInstanceIsValid
          def applicable?(record)
            record && (record.created? || record.built?) && !record.skip_validations
          end

          def expected_type_symbol
            :entity
          end
        end
      end
    end
  end
end
