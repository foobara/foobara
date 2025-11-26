module Foobara
  module BuiltinTypes
    module Attributes
      module Casters
        class Array < AssociativeArray::Casters::Array
          def applicable?(value)
            if super
              hash_caster.applicable?(to_h(value))
            end
          end

          def applies_message
            "be a an array of pairs"
          end

          def cast(array)
            hash_caster.cast(super)
          end

          private

          def hash_caster
            @hash_caster ||= Hash.instance
          end

          def to_h(value)
            method(:cast).super_method.call(value)
          end
        end
      end
    end
  end
end
