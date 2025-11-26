module Foobara
  module BuiltinTypes
    module Entity
      module Casters
        class PrimaryKey < DetachedEntity::Casters::PrimaryKey
          def build_method
            :thunk
          end
        end
      end
    end
  end
end
