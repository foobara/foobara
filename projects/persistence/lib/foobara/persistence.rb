module Foobara
  module Persistence
    class << self
      def reset_all
        Foobara.raise_if_production!("reset_all")
        @tables_for_entity_class_name = @bases = @default_crud_driver = @default_base = nil
        EntityBase::Transaction::Concerns::EntityCallbackHandling.reset_all
        EntityBase::Transaction.reset_all

        Util.descendants(Foobara::Entity).each do |entity_class|
          if entity_class.instance_variable_defined?(:@entity_base)
            entity_class.remove_instance_variable(:@entity_base)
          end
        end
      end

      def install!
        EntityBase::Transaction::Concerns::EntityCallbackHandling.install!
        EntityBase::Transaction.install!
      end
    end
  end
end
