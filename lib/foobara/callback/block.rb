module Foobara
  module Callback
    class Block
      class << self
        def for(type, callback)
          Callback.const_get("#{type.to_s.classify}Block").new(callback)
        end
      end

      attr_accessor :original_block

      def initialize(original_block)
        self.original_block = original_block
        validate_original_block!
      end

      def type
        @type ||= self.class.name.gsub(/Block$/, "").underscore
      end

      def call(...)
        to_proc.call(...)
      end

      def to_proc
        @to_proc ||= original_block
      end

      private

      def validate_original_block!
        validate_block_arguments_of_original_block!

        unless has_one_or_zero_positional_args?
          raise "Can't pass multiple arguments to a callback. Only 1 or 0 arguments."
        end
      end

      def validate_block_arguments_of_original_block!
        if takes_block?
          raise "#{type} callback block cannot accept a block"
        end
      end

      def takes_block?
        @takes_block ||= original_block.parameters.last&.first&.==(:block)
      end

      def has_one_or_zero_positional_args?
        @has_one_or_zero_positional_args ||= positional_args_count <= 1
      end

      def has_keyword_args?
        @has_keyword_args ||= param_types.any? { |type| %i[keyreq keyrest].include?(type) }
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