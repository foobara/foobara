module Foobara
  module Manifest
    class Processor < BaseManifest
      self.category_symbol = :processor

      def full_processor_name
        scoped_full_name
      end
    end
  end
end
