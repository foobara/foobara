module Foobara
  module Common
    class << self
      def install!
        Foobara.foobara_add_category_for_subclass_of(:processor_class, Value::Processor)
        Foobara.foobara_add_category_for_instance_of(:processor, Value::Processor)
        Foobara.foobara_add_category_for_subclass_of(:error, Error)
      end
    end
  end
end
