module Foobara
  module Domain
    class << self
      def reset_all
        Foobara.foobara_register(GlobalDomain)
        Foobara.foobara_register(GlobalOrganization)
      end

      def install!
        if @installed
          # :nocov:
          raise "Already registered Domain"
          # :nocov:
        end

        @installed = true

        # TODO: kill this concept!
        Util.make_module "Foobara::GlobalOrganization" do
          foobara_organization!

          self.is_global = true
        end

        Foobara::Command.include(Foobara::Domain::CommandExtension)

        Foobara.foobara_add_category(:organization) do
          is_a?(Module) && foobara_organization?
        end
        Foobara.foobara_add_category(:domain) do
          is_a?(Module) && foobara_domain?
        end
        Foobara.foobara_add_category_for_subclass_of(:command, Command)
        # TODO: should be able to access this as Type
        Foobara.foobara_add_category_for_instance_of(:type, Types::Type)
        Foobara.foobara_add_category_for_subclass_of(:processor, Value::Processor)
        Foobara.foobara_add_category_for_subclass_of(:error, Error)

        Types::Type.foobara_instances_are_namespaces!
      end
    end
  end
end
