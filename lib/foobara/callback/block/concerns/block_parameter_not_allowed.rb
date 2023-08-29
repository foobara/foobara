module Foobara
  module Callback
    class Block
      module Concerns
        module BlockParameterNotAllowed
          private

          def validate_original_block!
            super

            if takes_block?
              # :nocov:
              raise ArgumentError, "#{type} callback is not allowed to accept a block"
              # :nocov:
            end
          end
        end
      end
    end
  end
end
