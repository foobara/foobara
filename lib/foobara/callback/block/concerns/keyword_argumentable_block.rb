module Foobara
  module Callback
    module Concerns
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

        def validate_original_block!
          super

          if has_keyword_args? && has_positional_args?
            # TODO: raise a real error
            # :nocov:
            raise "Expect #{type} block to either take a positional arg or keyword args but not both"
            # :nocov:
          end
        end
      end
    end
  end
end
