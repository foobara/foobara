module Foobara
  # TODO: Make some kind of module to house these methods instead of the Command class
  class Service; end

  class Command
    class << self
      def install!
        Namespace.global.foobara_add_category_for_subclass_of(:command, self)
      end

      def reset_all
        to_delete = []

        all.each do |command_class|
          if command_class.name.include?("::")
            parent_name = Util.parent_module_name_for(command_class.name)

            if Object.const_defined?(parent_name)
              command_class.undefine_command_named_function
            else
              to_delete << command_class
            end
          else
            command_class.undefine_command_named_function
          end
        end

        to_delete.each do |command_class|
          all.delete(command_class)
        end

        super
      end
    end
  end
end
