module Foobara
  class Command < Service
    # TODO: this feels like a hack and shouldn't be necessary. Let's try to fix Concern class inheritance, instead.
    self.subclass_defined_callbacks ||= Foobara::Callback::Registry::SingleAction.new
  end

  Command.after_subclass_defined do |subclass|
    Command.all << subclass
    # TODO: can we kill this? I don't think anything uses this nor would need to.  Calling code could define such
    # helper methods if desired but could be a bad idea since it is nice for command calls to stick out as command
    # calls which would be less obvious if they just looked like random method calls.
    subclass.define_command_named_function
  end
end
