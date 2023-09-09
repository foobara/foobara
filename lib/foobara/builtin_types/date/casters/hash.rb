module Foobara
  module BuiltinTypes
    module Date
      module Casters
        class Hash < Value::Caster
          def applicable?(hash)
            hash.is_a?(::Hash) && hash.keys.size == 3 && (hash.keys.map(&:to_s).sort == %w[day month year])
          end

          def applies_message
            "be a Hash with :year, :month, and :day keys"
          end

          def cast(hash)
            hash = hash.symbolize_keys

            ::Date.new(hash[:year], hash[:month], hash[:day])
          end
        end
      end
    end
  end
end