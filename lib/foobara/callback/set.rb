require "foobara/callback"

module Foobara
  module Callback
    class Set
      attr_accessor :callbacks

      def initialize(callback_hash = {})
        self.callbacks = {}

        callback_hash.each do |type, blocks|
          send("#{type}=", blocks)
        end
      end

      def union(set)
        unioned = Set.new(callbacks)

        set.callbacks.each_pair do |type, blocks|
          next if blocks.empty?

          unioned_blocks = unioned[type]
          blocks.each { |block| unioned_blocks << block }
        end

        unioned
      end

      def [](type)
        send(type)
      end

      Foobara::Callback::ALLOWED_CALLBACK_TYPES.each do |method_name|
        define_method method_name do
          callbacks[method_name] ||= []
        end

        define_method "#{method_name}=" do |blocks|
          callbacks[method_name] ||= blocks
        end

        define_method "each_#{method_name}" do |&block|
          send(method_name).each(&block)
        end
      end
    end
  end
end
