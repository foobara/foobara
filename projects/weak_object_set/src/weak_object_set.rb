require "monitor"

module Foobara
  # TODO: a possible optimization: have a certain number of records before the Weakref approach kicks in
  # that way we don't just immediately clear out useful information without any actual memory burden
  class WeakObjectSet
    class GarbageCleaner
      attr_accessor :weak_object_set, :deactivated, :queue, :cleanup_thread

      def initialize(weak_object_set, queue)
        self.queue = queue
        self.weak_object_set = weak_object_set

        start_cleanup_thread
      end

      def cleanup_proc
        if deactivated?
          # :nocov:
          raise "GarbageCleaner has been deactivated"
          # :nocov:
        end

        @cleanup_proc ||= begin
          queue = self.queue

          ->(object_id) do
            unless deactivated?
              begin
                queue.push(object_id)
              rescue ClosedQueueError
                # :nocov:
                deactivate
                # :nocov:
              end
            end
          end
        end
      end

      def start_cleanup_thread
        queue = self.queue

        self.cleanup_thread = Thread.new do
          loop do
            object_id = queue.pop
            if object_id
              weak_object_set.delete(object_id)
            elsif queue.closed?
              self.queue = nil
              break
            else
              # :nocov:
              raise "Unexpected nil value in the queue"
              # :nocov:
            end
          end
        end

        cleanup_thread.priority = -2
      end

      def track(object)
        ObjectSpace.define_finalizer(object, cleanup_proc)
      end

      def deactivate
        raise if deactivated?

        self.deactivated = true
        queue.close
        # TODO: don't bother to join here outside of test suite
        cleanup_thread.join if ENV["FOOBARA_ENV"] == "test" # just doing this for test suite/simplecov
        @cleanup_proc = nil
        @queue = nil
        @weak_object_set = nil
        @cleanup_thread = nil
      end

      def deactivated?
        deactivated
      end
    end

    include Enumerable

    attr_accessor :monitor, :key_method, :key_to_object_id, :object_id_to_key, :objects, :closed
    attr_writer :garbage_cleaner

    def initialize(key_method = nil)
      self.key_method = key_method
      self.monitor = Monitor.new
      clear
    end

    def [](object_or_object_id)
      monitor.synchronize do
        ref = ref_for(object_or_object_id)

        # TODO: is this necessary? Why not check weakref_alive? now that we're in a mutex?
        object = begin
          ref&.__getobj__
        rescue WeakRef::RefError
          # :nocov:
          nil
          # :nocov:
        end

        if ref&.weakref_alive?
          object
        end
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
      monitor.synchronize do
        objects.each_value do |ref|
          # Is this still necessary now that we're in a mutex?
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
    end

    def size
      count
    end

    def empty?
      monitor.synchronize do
        objects.empty? || objects.values.none?(&:weakref_alive?)
      end
    end

    def garbage_cleaner
      @garbage_cleaner ||= begin
        queue = Queue.new

        GarbageCleaner.new(self, queue)
      end
    end

    def <<(object)
      if closed?
        # :nocov:
        raise "Cannot add objects to a closed WeakObjectSet"
        # :nocov:
      end

      object_id = object.object_id

      monitor.synchronize do
        existing_object = self[object_id]

        if existing_object
          if key_method
            key = object.send(key_method)
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

          if key_method
            key = object.send(key_method)

            if key
              existing_record_object_id = key_to_object_id[key]

              if existing_record_object_id
                # Sometimes this path is hit in the test suite and sometimes not, depending on
                # non-deterministic behavior of the garbage collector
                # :nocov:
                delete(existing_record_object_id)
                # :nocov:
              end

              key_to_object_id[key] = object_id
              object_id_to_key[object_id] = key
            end
          end

          objects[object_id] = WeakRef.new(object)

          object
        end
      end
    end

    def delete(object_or_object_id)
      object_id = if object_or_object_id.is_a?(::Integer)
                    object_or_object_id
                  else
                    object_or_object_id.object_id
                  end

      monitor.synchronize do
        if key_method
          key = object_id_to_key.delete(object_id)

          if key
            key_to_object_id.delete(key)
          end
        end

        objects.delete(object_id)
      end
    end

    def find_by_key(key)
      monitor.synchronize do
        unless key_method
          # :nocov:
          raise "Cannot find by key if there was no key_method given."
          # :nocov:
        end

        object_id = key_to_object_id[key]

        if object_id
          self[object_id]
        end
      end
    end

    def close
      raise if closed?

      self.closed = true
      stop_garbage_cleaner
    end

    def stop_garbage_cleaner
      gc = nil

      monitor.synchronize do
        if @garbage_cleaner
          gc = garbage_cleaner
          self.garbage_cleaner = nil
        end
      end

      gc&.deactivate
    end

    def clear
      monitor.synchronize do
        stop_garbage_cleaner

        self.objects = {}

        if key_method
          self.key_to_object_id = {}
          self.object_id_to_key = {}
        end
      end
    end

    def closed?
      closed
    end
  end
end
