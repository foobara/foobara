require "foobara/builtin_types/casters/direct_type_match"

module Foobara
  module BuiltinTypes
    module AssociativeArray
      module Casters
        class Hash < BuiltinTypes::Casters::DirectTypeMatch
          def initialize(*args)
            super(*args, ruby_classes: ::Hash)
          end

          def applicable?(value)
            value.is_a?(::Hash)
          end

          def applies_message
            "be a hash"
          end

          def cast(hash)
            hash
          end
        end
      end
    end
  end
end
