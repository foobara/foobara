module Foobara
  module Callback
    class Set
      attr_accessor :callbacks

      def initialize(callback_hash = {})
        self.callbacks = {}

        callback_hash.each do |type, blocks|
          send("#{type}=", blocks.dup)
        end
      end

      foobara_delegate :size, to: :callbacks

      def union(set)
        unioned = Set.new(callbacks)

        set.callbacks.each_pair do |type, blocks|
          next if blocks.empty?

          unioned_blocks = unioned[type]
          blocks.each { |block| unioned_blocks << block }
        end

        unioned
      end

      def |(other)
        union(other)
      end

      def [](type)
        send(type)
      end

      Block.types.each do |type|
        define_method type do
          callbacks[type] ||= []
        end

        define_method "#{type}=" do |blocks|
          callbacks[type] ||= blocks
        end

        define_method "each_#{type}" do |&block|
          send(type).each(&block)
        end

        define_method "has_#{type}_callbacks?" do
          !send(type).empty?
        end
      end
    end
  end
end
