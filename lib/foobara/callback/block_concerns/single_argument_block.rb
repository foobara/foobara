module Foobara
  module Callback
    module SingleArgumentBlock
      private

      def validate_original_block!
        super

        if has_keyword_args?
          raise "Expect #{type} block to only receive one or zero arguments. It cannot take keyword arguments."
        end
      end
    end
  end
end
