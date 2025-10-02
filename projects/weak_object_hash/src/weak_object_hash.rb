require "monitor"

module Foobara
  # TODO: a possible optimization: have a certain number of records before the Weakref approach kicks in
  # that way we don't just immediately clear out useful information without any actual memory burden
  class WeakObjectHash
    class ClosedError < StandardError; end

    attr_accessor :object_ids_to_values_and_weak_refs, :monitor, :closed
    attr_writer :skip_finalizer

    def initialize
      self.monitor = Monitor.new
      self.object_ids_to_values_and_weak_refs = {}
    end

    def []=(object, value)
      object_id = object.object_id
      weak_ref = WeakRef.new(object)

      if closed?
        raise ClosedError, "Cannot add objects to a closed WeakObjectHash"
      end

      monitor.synchronize do
        delete(object)

        object_ids_to_values_and_weak_refs[object_id] = [weak_ref, value]

        unless skip_finalizer?
          ObjectSpace.define_finalizer(object, finalizer_proc)
        end

        value
      end
    end

    def [](object)
      object_id = object.object_id

      if closed?
        raise ClosedError, "Cannot retrieve objects from a closed WeakObjectHash"
      end

      monitor.synchronize do
        pair = object_ids_to_values_and_weak_refs[object_id]

        return nil unless pair

        weak_ref, value = pair

        if weak_ref.weakref_alive?
          if weak_ref.__getobj__ != object
            # :nocov:
            raise "Unexpected, weak ref's object doesn't match the stored key object"
            # :nocov:
          end

          value
        else
          # Seems unreachable... if it's been garbage collected how could we have a reference to the object
          # to pass it in?
          # :nocov:
          object_ids_to_values_and_weak_refs.delete(object_id)

          nil
          # :nocov:
        end
      end
    end

    def delete(object)
      object_id = object.object_id

      monitor.synchronize do
        pair = object_ids_to_values_and_weak_refs.delete(object_id)

        return nil unless pair

        weak_ref, value = pair

        if weak_ref.weakref_alive?
          object = weak_ref.__getobj__

          if weak_ref.__getobj__ != object
            # :nocov:
            raise "Unexpected, weak ref's object doesn't match the stored key object"
            # :nocov:
          end

          # Hmmm, there's seemingly no safe way to remove the finalizer for the previous entry
          # if it exists. This is because we can only remove all finalizers on object. Not only
          # the ones we've created.
          # We will just do this anyway with that caveat and maybe make this configuratble in the future.
          unless skip_finalizer?
            ObjectSpace.undefine_finalizer(object)
          end

          value
        end
      end
    end

    def each_pair
      monitor.synchronize do
        object_ids_to_values_and_weak_refs.each_pair do |object_id, pair|
          weak_ref, value = pair

          if weak_ref.weakref_alive?
            yield weak_ref.__getobj__, value
          else
            object_ids_to_values_and_weak_refs.delete(object_id)
          end
        end
      end

      self
    end

    def values
      values = []

      monitor.synchronize do
        each_pair do |_key, value|
          values << value
        end
      end

      values
    end

    def keys
      keys = []

      monitor.synchronize do
        each_pair do |key, _value|
          keys << key
        end
      end

      keys
    end

    def size
      size = 0
      to_delete = nil

      monitor.synchronize do
        object_ids_to_values_and_weak_refs.each_pair do |object_id, pair|
          weak_ref = pair.first

          if weak_ref.weakref_alive?
            size += 1
          else
            to_delete ||= []
            to_delete << object_id
          end
        end

        to_delete&.each do |object_id|
          object_ids_to_values_and_weak_refs.delete(object_id)
        end
      end

      size
    end

    def empty?
      size == 0
    end

    def close!
      if closed?
        raise ClosedError, "Already closed"
      end

      monitor.synchronize do
        self.closed = true
        clear
        @finalizer_proc = nil
        self.object_ids_to_values_and_weak_refs = nil
        self.monitor = nil
      end
    end

    def clear
      monitor.synchronize do
        object_ids_to_values_and_weak_refs.each_value do |pair|
          weak_ref = pair.first

          if weak_ref.weakref_alive?
            unless skip_finalizer?
              ObjectSpace.undefine_finalizer(weak_ref.__getobj__)
            end
          end
        end

        object_ids_to_values_and_weak_refs.clear
      end
    end

    def closed?
      closed
    end

    def skip_finalizer?
      @skip_finalizer
    end

    private

    def finalizer_proc
      @finalizer_proc ||= ->(object_id) do
        unless closed?
          object_ids_to_values_and_weak_refs.delete(object_id)
        end
      end
    end
  end
end
