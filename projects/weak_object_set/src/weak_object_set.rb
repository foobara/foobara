require "weakref"

module Foobara
  class WeakObjectSet
    class GarbageCleaner
      def initialize(objects, key_to_object_id = nil, object_id_to_key = nil)
        @objects = objects
        @key_to_object_id = key_to_object_id
        @object_id_to_key = object_id_to_key
      end

      def cleanup_proc
        @cleanup_proc ||= ->(object_id) {
          unless @deactivated
            @objects.delete(object_id)

            key = @object_id_to_key&.delete(object_id)

            if key
              @key_to_object_id.delete(key)
            end
          end
        }
      end

      def track(object)
        if @deactivated
          # :nocov:
          raise "Cannot track anymore objects since we have been deactivated"
          # :nocov:
        end

        ObjectSpace.define_finalizer(object, cleanup_proc)
      end

      def deactivate
        @deactivated = true
      end
    end

    include Enumerable

    def initialize(key_method = nil)
      @key_method = key_method
    end

    def [](object_or_object_id)
      ref = ref_for(object_or_object_id)

      if ref&.weakref_alive?
        ref.__getobj__
      end
    end

    def ref_for(object_or_object_id)
      object_id = if object_or_object_id.is_a?(::Integer)
                    object_or_object_id
                  else
                    object_or_object_id.object_id
                  end

      objects[object_id]
    end

    def each
      objects.each_value do |ref|
        if ref.weakref_alive?
          yield ref.__getobj__
        end
      end
    end

    def objects
      @objects ||= {}
    end

    def size
      count
    end

    def empty?
      objects.empty? || objects.values.none?(&:weakref_alive?)
    end

    def key_to_object_id
      @key_to_object_id ||= {}
    end

    def object_id_to_key
      @object_id_to_key ||= {}
    end

    def garbage_cleaner
      @garbage_cleaner ||= if @key_method
                             GarbageCleaner.new(objects, key_to_object_id, object_id_to_key)
                           else
                             GarbageCleaner.new(objects)
                           end
    end

    def <<(object)
      garbage_cleaner.track(object)

      object_id = object.object_id

      objects[object_id] = WeakRef.new(object)

      if @key_method
        key = object.send(@key_method)

        if key
          key_to_object_id[key] = object_id
          object_id_to_key[object_id] = key
        end
      end

      object
    end

    def include?(object_or_object_id)
      ref_for(object_or_object_id)&.weakref_alive?
    end

    def delete(object)
      if @key_method
        key = @object_id_to_key&.delete(object.object_id)

        if key
          @key_to_object_id.delete(key)
        end
      end

      objects.delete(object)
    end

    def include_key?(key)
      unless @key_method
        # :nocov:
        raise "Cannot check by key if there was no key_method given."
        # :nocov:
      end

      objects[key_to_object_id[key]]&.weakref_alive?
    end

    def find_by_key(key)
      unless @key_method
        # :nocov:
        raise "Cannot find by key if there was no key_method given."
        # :nocov:
      end

      object = objects[key_to_object_id[key]]

      if object&.weakref_alive?
        object.__getobj__
      end
    end

    def clear
      @garbage_cleaner&.deactivate
      @key_to_object_id = @object_id_to_key = @objects = @garbage_cleaner = nil
    end
  end
end
