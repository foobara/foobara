module Foobara
  class Domain
    class << self
      def reset_all
        %w[
          all
          global
          foobara_organization_modules
          foobara_domain_modules
          unprocessed_command_classes
        ].each do |var_name|
          var_name = "@#{var_name}"
          remove_instance_variable(var_name) if instance_variable_defined?(var_name)
        end

        %w[
          children
          registry
        ].each do |var_name|
          var_name = "@#{var_name}"

          [
            Foobara,
            Domain,
            Command,
            Types::Type,
            Value::Processor,
            Error
          ].each do |klass|
            klass.remove_instance_variable(var_name) if klass.instance_variable_defined?(var_name)
          end
        end
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

          class << self
            def foobara_domains
              # TODO: kill global? concept
              if global?
                [*Foobara.foobara_all_domain(lookup_in_children: false).map(&:foobara_domain), Domain.global]
              else
                foobara_all_domain(lookup_in_children: false).map(&:foobara_domain)
              end
            end
          end
        end

        # Foobara.foobara_organization!
        Foobara::Command.include(Foobara::Domain::CommandExtension)
        Foobara::Command.after_subclass_defined do |subclass|
          unprocessed_command_classes << subclass
        end

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
