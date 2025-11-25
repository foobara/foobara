module Foobara
  module Callback
    class Block
      module Concerns
        module BlockParameterNotAllowed
          class BlockParameterNotAllowedError < StandardError; end

          private

          def validate_original_block!
            super

            if takes_block?
              raise BlockParameterNotAllowedError, "#{type} callback is not allowed to accept a block"
            end
          end
        end
      end
    end
  end
end
