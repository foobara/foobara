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

        Foobara::Command.include(Foobara::Domain::CommandExtension)
        # Feels so odd to have this here but the manifest definition elsewhere
        Foobara::Value::Processor.include Manifestable
        Foobara::Error.include Manifestable
        Foobara::Types::Type.include IsManifestable

        Foobara.foobara_add_category(:organization) do
          is_a?(Module) && foobara_organization?
        end
        Foobara.foobara_add_category(:domain) do
          is_a?(Module) && foobara_domain?
        end
        Foobara.foobara_add_category_for_subclass_of(:command, Command)
        # TODO: should be able to access this as Type
        Foobara.foobara_add_category_for_instance_of(:type, Types::Type)
        Foobara.foobara_add_category_for_subclass_of(:processor_class, Value::Processor)
        Foobara.foobara_add_category_for_instance_of(:processor, Value::Processor)
        Foobara.foobara_add_category_for_subclass_of(:error, Error)

        Types::Type.foobara_instances_are_namespaces!
      end
    end
  end
end
