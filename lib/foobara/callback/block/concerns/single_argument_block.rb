module Foobara
  module Callback
    module Concerns
      module SingleArgumentBlock
        private

        def validate_original_block!
          super

          if has_keyword_args?
            # :nocov:
            raise ArgumentError,
                  "Expect #{type} block to only receive one or zero arguments. It cannot take keyword arguments."
            # :nocov:
          end
        end
      end
    end
  end
end
