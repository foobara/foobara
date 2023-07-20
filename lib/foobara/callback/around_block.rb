require "foobara/callback/block"

module Foobara
  module Callback
    class AroundBlock < Block
      def to_proc
        @to_proc ||= if has_keyword_args?
                       proc do |*args, &block|
                         keyword_args = args.reduce(:merge)

                         original_block.call(**keyword_args, &block)
                       end
                     else
                       original_block
                     end
      end

      private

      def validate_original_block!
        unless takes_block?
          raise "Around callback must take a block argument to receive the do_it block"
        end

        if has_keyword_args?
          if has_positional_args?
            raise "Callback block can't both accept keyword arguments and also a positional argument"
          end
        elsif !has_one_or_zero_positional_args?
          raise "Can't pass multiple arguments to a callback. Only 1 or 0 arguments."
        end
      end
    end
  end
end
