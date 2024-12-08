module Foobara
  class DetachedEntity
    module Concerns
      module Equality
        include Concern

        def dup
          # TODO: Maybe raise instead?
          self
        end

        def ==(other)
          # Should both records be required to be persisted to be considered equal when having matching primary keys?
          # For now we will consider them equal but it could make sense to consider them not equal.
          equal?(other) || (self.class == other.class && primary_key && primary_key == other.primary_key)
        end

        def hash
          (primary_key || object_id).hash
        end
      end
    end
  end
end
