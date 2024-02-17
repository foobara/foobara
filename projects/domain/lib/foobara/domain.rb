module Foobara
  module Domain
    class << self
      def install!
        if @installed
          # :nocov:
          raise "Already registered Domain"
          # :nocov:
        end

        @installed = true

        Foobara::Value::Processor.include Manifestable
        Foobara::Value::Processor.include IsManifestable
        Foobara::Error.include Manifestable

        Foobara.foobara_add_category(:organization) do
          is_a?(Module) && foobara_organization?
        end
        Foobara.foobara_add_category(:domain) do
          is_a?(Module) && foobara_domain?
        end

        Foobara.foobara_add_category_for_subclass_of(:processor_class, Value::Processor)
        Foobara.foobara_add_category_for_instance_of(:processor, Value::Processor)
        Foobara.foobara_add_category_for_subclass_of(:error, Error)
      end
    end
  end
end
