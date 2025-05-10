module Foobara
  class WeakObjectSet
    class GarbageCleaner
      class InvalidWtf < StandardError; end

      def initialize(objects, key_to_object_id = nil, object_id_to_key = nil)
        @objects = objects
        @key_to_object_id = key_to_object_id
        @object_id_to_key = object_id_to_key
      end

      def cleanup_proc
        @cleanup_proc ||= ->(object_id) {
          unless @deactivated
            puts "before"
            puts "objects: #{@objects.keys.inspect}"
            puts "object_id_to_key: #{@object_id_to_key.inspect}"
            puts "key_to_object_id: #{@key_to_object_id.inspect}"
            puts "GC: deleting #{object_id}"
            @objects.delete(object_id)

            present = @object_id_to_key&.key?(object_id)
            if present
              puts "GC: deleting #{object_id} from object_id_to_key"
            end
            key = @object_id_to_key&.delete(object_id)

            if key
              if present
                puts "GC: deleting #{key} from key_to_object_id"
              end
              @key_to_object_id.delete(key)
            end
            if @object_id_to_key.size != @key_to_object_id.size
              binding.pry
            end

            puts "after"
            puts "objects: #{@objects.keys.inspect}"
            puts "object_id_to_key: #{@object_id_to_key.inspect}"
            puts "key_to_object_id: #{@key_to_object_id.inspect}"
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

      object = begin
        ref&.__getobj__
      rescue WeakRef::RefError # I don't think this rescue is necessary but not certain
        nil
      end

      if ref&.weakref_alive?
        object
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
        object = begin
          ref.__getobj__
        rescue WeakRef::RefError
          nil
        end

        if ref.weakref_alive?
          yield object
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
      validate_for(object)
      validate!
      object_id = object.object_id

      if include?(object)
        if @key_method
          key = object.send(@key_method)
          old_key = object_id_to_key[object_id]

          if key != old_key
            key_to_object_id.delete(old_key)

            if key
              key_to_object_id[key] = object_id
              object_id_to_key[object_id] = key
            else
              object_id_to_key.delete(object_id)
            end
          end
        end
      else
        garbage_cleaner.track(object)

        objects[object_id] = WeakRef.new(object)

        if @key_method
          key = object.send(@key_method)

          if key
            key_to_object_id[key] = object_id
            object_id_to_key[object_id] = key
          end
        end

        object
      end.tap do
        validate!
      end
    end

    def delete(object)
      validate!

      if @key_method
        present = @object_id_to_key&.key?(object.object_id)

        if present
          puts "deleting #{object_id} #{object} from object_id_to_key"
        end
        key = @object_id_to_key&.delete(object.object_id)

        if key
          if present
            puts "deleting #{key} from key_to_object_id"
          end
          @key_to_object_id.delete(key)
        elsif present
          puts "no key!"
        end
      end

      objects.delete(object.object_id).tap { validate! }
    end

    def find_by_key(key)
      unless @key_method
        # :nocov:
        raise "Cannot find by key if there was no key_method given."
        # :nocov:
      end

      object_id = key_to_object_id[key]

      if object_id
        self[object_id]
      end
    end

    def clear
      validate!
      @garbage_cleaner&.deactivate
      @key_to_object_id = @object_id_to_key = @objects = @garbage_cleaner = nil
      validate!
    end

    def validate!
      # puts "validating!"
      if (@object_id_to_key&.size || 0) != (@key_to_object_id&.size || 0)
        puts "whoa"
        binding.pry
        raise InvalidWtf
      end
    end

    def validate_for(object)
      if @key_method
        key = object.send(@key_method)

        if key

          by_key = find_by_key(key)

          if by_key
            if self[object].object_id != find_by_key(key).object_id
              binding.pry
              raise InvalidWtf
            end
          elsif self[object] && !object.created?
            binding.pry
            raise InvalidWtf
          end
        end
      end
    end
  end
end
