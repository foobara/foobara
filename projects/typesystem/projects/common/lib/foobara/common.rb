module Foobara
  module Common
    class << self
      def install!
        Namespace.global.foobara_add_category_for_subclass_of(:processor_class, Value::Processor)
        Namespace.global.foobara_add_category_for_instance_of(:processor, Value::Processor)
        Namespace.global.foobara_add_category_for_subclass_of(:error, Error)
      end
    end
  end
end

Foobara.project("common", project_path: "#{__dir__}/../..")
