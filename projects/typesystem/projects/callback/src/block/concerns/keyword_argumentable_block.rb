module Foobara
  module Callback
    class Block
      module Concerns
        module KeywordArgumentableBlock
          def to_proc
            @to_proc ||= if has_keyword_args?
                           proc do |*args, &block|
                             original_block.call(**args.reduce(:merge), &block)
                           end
                         else
                           original_block
                         end
          end

          private

          def validate_original_block!
            super

            if has_keyword_args? && has_positional_args?
              # TODO: raise a real error
              # simplecov:disable
              raise "Expect #{type} block to either take a positional arg or keyword args but not both"
              # simplecov:enable
            end
          end
        end
      end
    end
  end
end
