require "foobara/builtin_types/casters/direct_type_match"

module Foobara
  module BuiltinTypes
    module Boolean
      module Casters
        class Boolean < BuiltinTypes::Casters::DirectTypeMatch
          def initialize(*args)
            super(*args, ruby_classes: [::TrueClass, ::FalseClass])
          end
        end
      end
    end
  end
end
