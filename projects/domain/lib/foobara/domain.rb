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

        Organization.reset_all

        %w[
          children
          registry
        ].each do |var_name|
          var_name = "@#{var_name}"

          [
            Foobara,
            Organization,
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
        Foobara.foobara_organization!
        Foobara::Command.include(Foobara::Domain::CommandExtension)
        Foobara::Command.after_subclass_defined do |subclass|
          unprocessed_command_classes << subclass
        end

        Foobara.foobara_root_namespace!

        Foobara.foobara_add_category_for_instance_of(:organization, Organization)
        Foobara.foobara_add_category_for_instance_of(:domain, Domain)
        Foobara.foobara_add_category_for_subclass_of(:command, Command)
        # TODO: should be able to access this as Type
        Foobara.foobara_add_category_for_instance_of(:type, Types::Type)
        Foobara.foobara_add_category_for_subclass_of(:processor, Value::Processor)
        Foobara.foobara_add_category_for_subclass_of(:error, Error)
      end
    end
  end
end
