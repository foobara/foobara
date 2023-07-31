module Foobara
  module Callback
    module Concerns
      module SingleArgumentBlock
        private

        def validate_original_block!
          super

          if has_keyword_args?
            # TODO: raise a real error
            raise "Expect #{type} block to only receive one or zero arguments. It cannot take keyword arguments."
          end
        end
      end
    end
  end
end
