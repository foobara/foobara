module Foobara
  module Persistence
    class EntityBase
      class Transaction
        module Concerns
          module EntityCallbackHandling
            module ClassMethods
            end
          end
        end

        # Entity.after_subclass_defined do |entity_class|
        # end

        # TODO: maybe use class-level callbacks to improve performance?
        Entity.after_dirtied do |record:, **|
          binding.pry
        end

        Entity.after_undirtied do |record:, **|
          binding.pry
        end

        Entity.after_hard_deleted do |record:, **|
          binding.pry
        end

        Entity.after_unhard_deleted do |record:, **|
          binding.pry
        end

        Entity.after_initialized_thunk do |record:, **|
          binding.pry
        end

        Entity.after_initialized_loaded do |record:, **|
          binding.pry
        end

        Entity.after_initialized_created do |record:, **|
          binding.pry
        end
      end
    end
  end
end
