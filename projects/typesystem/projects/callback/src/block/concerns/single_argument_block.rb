module Foobara
  module Callback
    class Block
      module Concerns
        module SingleArgumentBlock
          private

          def validate_original_block!
            super

            if has_keyword_args?
              # simplecov:disable
              raise ArgumentError,
                    "Expect #{type} block to only receive one or zero arguments. It cannot take keyword arguments."
              # simplecov:enable
            end
          end
        end
      end
    end
  end
end
