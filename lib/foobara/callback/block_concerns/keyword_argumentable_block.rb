module Foobara
  module Callback
    module KeywordArgumentableBlock
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
    end
  end
end
