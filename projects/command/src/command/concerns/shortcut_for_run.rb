module Foobara
  class Command < Service
    module Concerns
      module ShortcutForRun
        include Concern

        on_include do
          Command.after_subclass_defined do |subclass|
            Command.all << subclass
            # This results in being able to use the command class name instead of .run! if you want.
            # So instead of DoIt.run!(inputs) you can just do DoIt(inputs)
            # TODO: can we kill this? I don't think anything uses this nor would really need to.  Calling code could define such
            # helper methods if desired but could be a bad idea since it is nice for command calls to stick out as command
            # calls which would be less obvious if they just looked like random method calls (except that they are class case
            # instead of underscore case)
            subclass.define_command_named_function
          end
        end

        module ClassMethods
          def define_command_named_function
            command_class = self
            convenience_method_name = Foobara::Util.non_full_name(command_class)
            containing_module = Foobara::Util.module_for(command_class) || Object

            if containing_module.is_a?(::Class)
              containing_module.singleton_class.define_method convenience_method_name do |*args, **opts, &block|
                command_class.run!(*args, **opts, &block)
              end

              containing_module.define_method convenience_method_name do |*args, **opts, &block|
                command_class.run!(*args, **opts, &block)
              end
            else
              containing_module.module_eval do
                module_function

                define_method convenience_method_name do |*args, **opts, &block|
                  command_class.run!(*args, **opts, &block)
                end
              end
            end
          end

          def undefine_command_named_function
            command_class = self
            convenience_method_name = Foobara::Util.non_full_name(command_class)
            containing_module = Foobara::Util.module_for(command_class) || Object

            return unless containing_module.respond_to?(convenience_method_name)

            containing_module.singleton_class.undef_method convenience_method_name

            if containing_module.is_a?(::Class)
              containing_module.undef_method convenience_method_name
            end
          end
        end
      end
    end
  end
end
