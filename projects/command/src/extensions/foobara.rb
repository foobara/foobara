module Foobara
  class << self
    def all_commands
      Namespace.global.foobara_all_command
    end
  end
end
