require "foobara/callback/block"

module Foobara
  module Callback
    class ErrorBlock < Block
      def to_proc
        @to_proc ||= original_block
      end

      private

      def validate_original_block!
        if takes_block?
          raise "#{type} callback block cannot accept a block"
        end

        if has_keyword_args?
          raise "Expect error block to only receive one argument which is the UnexpectedErrorWhileRunningCallback. " \
                "It cannot take keyword arguments."
        elsif !has_one_or_zero_positional_args?
          raise "Can't pass multiple arguments to a callback. Only 1 or 0 arguments."
        end
      end
    end
  end
end
