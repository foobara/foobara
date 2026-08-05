module Foobara
  module Callback
    class Block
      module Concerns
        module BlockParameterRequired
          private

          def validate_original_block!
            super

            unless takes_block?
              # simplecov:disable
              raise ArgumentError, "#{type} callback must take a block argument"
              # simplecov:enable
            end
          end
        end
      end
    end
  end
end
