Foobara::Util.require_directory("#{__dir__}/block")

module Foobara
  module Callback
    class Block
      include Concerns::Type

      class << self
        def types_to_subclasses
          @types_to_subclasses ||= subclasses.to_h { |klass| [klass.type, klass] }
        end

        def types
          @types ||= types_to_subclasses.keys
        end

        def for(type, callback)
          const_get(type.to_s.camelize).new(callback)
        end
      end

      attr_accessor :original_block

      def initialize(original_block)
        self.original_block = original_block
        validate_original_block!
      end

      delegate :type, to: :class

      def call(...)
        to_proc.call(...)
      end

      def to_proc
        @to_proc ||= original_block
      end

      private

      def validate_original_block!
        unless has_one_or_zero_positional_args?
          # TODO: raise a real error
          # :nocov:
          raise "Can't pass multiple arguments to a callback. Only 1 or 0 arguments."
          # :nocov:
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

      def has_positional_args?
        @has_positional_args ||= positional_args_count > 0
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
