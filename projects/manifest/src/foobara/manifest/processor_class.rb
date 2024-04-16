module Foobara
  module Manifest
    class ProcessorClass < BaseManifest
      self.category_symbol = :processor_class

      def full_processor_class_name
        scoped_full_name
      end
    end
  end
end
