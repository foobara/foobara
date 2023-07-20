module Foobara
  module Callback
    class Block
      attr_accessor :original_block, :type

      def initialize(type, original_block)
        self.type = type # TODO: eliminate this with classes
        self.original_block = original_block
        validate_original_block!
      end

      def to_proc
        @to_proc ||= if has_keyword_args?
                       proc do |*args|
                         keyword_args = args.reduce(:merge)

                         original_block.call(**keyword_args)
                       end
                     else
                       original_block
                     end
      end

      def call(...)
        to_proc.call(...)
      end

      private

      def validate_original_block!
        if takes_block?
          if type != :around
            raise "#{type} callback block cannot accept a block"
          end
        elsif type == :around
          raise "Around callback must take a block argument to receive the do_it block"
        end

        if has_keyword_args?
          if type == :error
            raise "Expect error block to only receive one argument which is the UnexpectedErrorWhileRunningCallback. " \
                  "It cannot take keyword arguments."
          end

          if has_positional_args?
            raise "Callback block can't both accept keyword arguments and also a positional argument"
          end
        elsif !has_one_or_zero_positional_args?
          raise "Can't pass multiple arguments to a callback. Only 1 or 0 arguments."
        end
      end

      def validate_error_block!
        if takes_block?
          raise "callback block can't take a block"
        end
      end

      def takes_block?
        @takes_block ||= original_block.parameters.last&.first&.==(:block)
      end

      def has_no_args_ignoring_block
        @has_no_args_ignoring_block ||= param_types_ignoring_block.empty?
      end

      def has_one_or_zero_positional_args?
        @has_one_or_zero_positional_args ||= positional_args_count <= 1
      end

      def has_one_positional_arg?
        @has_one_positional_arg ||= positional_args_count == 1
      end

      def has_positional_args?
        @has_positional_args ||= !positional_args_count.zero?
      end

      def has_keyword_args?
        @has_keyword_args ||= param_types.any? { |type| %i[keyreq keyrest].include?(type) }
      end

      def param_types_ignoring_block
        @param_types_ignoring_block ||= param_types.reject { |type| type == :block }
      end

      def param_types
        @param_types ||= original_block.parameters.map(&:first)
      end

      def optional_positional_args_count
        @optional_positional_args_count ||= original_block.parameters.map(&:first).count { |type| type == :opt }
      end

      def required_positional_args_count
        @required_positional_args_count ||= original_block.parameters.map(&:first).count { |type| type == :req }
      end

      def positional_args_count
        @positional_args_count ||= optional_positional_args_count + required_positional_args_count
      end
    end
  end
end
