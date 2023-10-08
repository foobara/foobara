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
      end
    end
  end
end
