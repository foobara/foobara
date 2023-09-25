module Foobara
  module Persistence
    class << self
      def reset_all
        @tables_for_entity_class_name = @bases = @default_crud_driver = @default_base = nil
      end

      def install!
        EntityBase::Transaction::Concerns::EntityCallbackHandling.install!
      end
    end
  end
end
